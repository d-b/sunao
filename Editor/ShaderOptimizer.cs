using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using System.Text;
using System.Globalization;

namespace SunaoShader
{
    public class ShaderOptimizer
    {
        public static bool Lock(Material material, MaterialProperty[] props)
        {
            // File filepaths and names
            Shader shader = material.shader;
            string shaderFilePath = AssetDatabase.GetAssetPath(shader);
            string materialFilePath = AssetDatabase.GetAssetPath(material);
            string materialFolder = Path.GetDirectoryName(materialFilePath);
            string guid = Guid.NewGuid().ToString();
            string newShaderName = shader.name + ".Optimized/" + material.name + "-" + guid;
            string newShaderFileName = Path.GetFileNameWithoutExtension(shaderFilePath) + "_" + material.name + "-" + guid + ".shader";
            string newShaderFilePath = materialFolder + "/Optimized/" + newShaderFileName;

            // Generate the new shader
            string newShaderBody = GenerateShader(shaderFilePath, newShaderName, props);

            // Write the shader to disk
            (new FileInfo(newShaderFilePath)).Directory.Create();
            try {
                StreamWriter sw = new StreamWriter(newShaderFilePath);
                sw.Write(newShaderBody);
                sw.Close();
            }
            catch (IOException e) {
                Debug.LogError("Optimized shader " + newShaderFilePath + " could not be written: " + e.ToString());
                return false;
            }

            AssetDatabase.Refresh();
            // Write original shader to override tag
            material.SetOverrideTag("OriginalShader", shader.name);
            // Write the new shader path in an override tag so it will be deleted
            material.SetOverrideTag("OptimizedShaderPath", newShaderFilePath);

            // For some reason when shaders are swapped on a material the RenderType override tag gets completely deleted and render queue set back to -1
            // So these are saved as temp values and reassigned after switching shaders
            string renderType = material.GetTag("RenderType", false, "");
            int renderQueue = material.renderQueue;

            // Actually switch the shader
            Shader newShader = Shader.Find(newShaderName);
            if (newShader == null) {
                Debug.LogError("Optimized shader " + newShaderName + " could not be found");
                return false;
            }
            material.shader = newShader;
            material.SetOverrideTag("RenderType", renderType);
            material.renderQueue = renderQueue;

            return true;
        }

        private static string GenerateDefines(MaterialProperty[] props) {
            StringBuilder sb = new StringBuilder();

            sb.AppendLine("#define OPTIMIZED_SHADER 1");
            foreach (MaterialProperty prop in props) {
                if (prop != null && prop.type == MaterialProperty.PropType.Float)
                    sb.AppendLine("#define PROP_" + ToSnakeCase(prop.name) + " " + prop.floatValue);
            }

            return sb.ToString();
        }

        private static string ToSnakeCase(string str)
        {
            Regex pattern = new Regex(@"[A-Z]{2,}(?=[A-Z][a-z]+[0-9]*|\b)|[A-Z]?[a-z]+[0-9]*|[A-Z]|[0-9]+");
            return string.Join("_", pattern.Matches(str).Cast<Match>().Select(m => m.Value)).ToUpper();
        }

        private static string GenerateShader(string shaderPath, string shaderName, MaterialProperty[] props) {
            string basePath = Path.GetDirectoryName(shaderPath).Replace("\\", "/") + "/";

            Regex shaderPattern = new Regex(@"\s*Shader\s+""(.*?)""(.*)");
            Regex includePattern = new Regex(@"\s*#include\s+""(?i)(?!Assets[\\/])(.[\\/])?(.*?)""");
            Regex cgprogramPattern = new Regex(@"\s*CGPROGRAM\s*");

            StringBuilder sb = new StringBuilder();
            List<string> shaderLines = File.ReadAllLines(shaderPath).ToList();

            string generatedDefines = GenerateDefines(props);

            foreach(string line in shaderLines) {
                MatchCollection shaderMatches = shaderPattern.Matches(line);
                MatchCollection includeMatches = includePattern.Matches(line);

                if (shaderMatches.Count > 0) {
                    sb.AppendLine("Shader \"" + shaderName + "\"" + shaderMatches[0].Groups[2].Captures[0].Value);
                } else if (includeMatches.Count > 0) {
                    string path = Path.Combine(basePath, includeMatches[0].Groups[2].Captures[0].Value);
                    sb.AppendLine("#include \"" + path + "\"");
                } else {
                    sb.AppendLine(line);
                }

                MatchCollection matches = cgprogramPattern.Matches(line);
                if (matches.Count > 0) sb.Append(generatedDefines);
            }

            return sb.ToString();
        }

        public static bool Unlock(Material material)
        {
            // Revert to original shader
            string originalShaderName = material.GetTag("OriginalShader", false, "");
            if (originalShaderName == "") {
                Debug.LogError("Original shader not saved to material, could not unlock shader");
                return false;
            }

            Shader orignalShader = Shader.Find(originalShaderName);
            if (orignalShader == null) {
                Debug.LogError("Original shader " + originalShaderName + " could not be found");
                return false;
            }

            // For some reason when shaders are swapped on a material the RenderType override tag gets completely deleted and render queue set back to -1
            // So these are saved as temp values and reassigned after switching shaders
            string renderType = material.GetTag("RenderType", false, "");
            int renderQueue = material.renderQueue;
            material.shader = orignalShader;
            material.SetOverrideTag("RenderType", renderType);
            material.renderQueue = renderQueue;

            // Delete the optimized shader file
            string shaderFilePath = material.GetTag("OptimizedShaderPath", false, "");
            if (shaderFilePath == "") {
                Debug.LogError("Optimized shader folder could not be found, not deleting anything");
                return false;
            }

            AssetDatabase.DeleteAsset(shaderFilePath);
            AssetDatabase.Refresh();

            return true;
        }
    }
}
