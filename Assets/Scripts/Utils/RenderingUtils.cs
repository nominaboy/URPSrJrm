using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public static class RenderingUtils {
    private static Mesh s_FullScreenMesh = null;









    public static Mesh FullScreenMesh {
        get {
            if (s_FullScreenMesh != null) {
                return s_FullScreenMesh;
            }

            float topV = 1.0f;
            float bottomV = 0.0f;

            s_FullScreenMesh = new Mesh { name = "FullScreenQuad" };
            s_FullScreenMesh.SetVertices(new List<Vector3> {
                new Vector3(-1.0f, -1.0f, 0.0f),
                new Vector3(-1.0f, 1.0f, 0.0f),
                new Vector3(1.0f, -1.0f, 0.0f),
                new Vector3(1.0f, 1.0f, 0.0f)
            });

            s_FullScreenMesh.SetUVs(0, new List<Vector2> {
                new Vector2(0.0f, bottomV),
                new Vector2(0.0f, topV),
                new Vector2(1.0f, bottomV),
                new Vector2(1.0f, topV)
            });

            s_FullScreenMesh.SetIndices(new[] { 0, 1, 2, 2, 1, 3 }, MeshTopology.Triangles, 0, false);
            s_FullScreenMesh.UploadMeshData(true);
            return s_FullScreenMesh;
        }

    }
}
