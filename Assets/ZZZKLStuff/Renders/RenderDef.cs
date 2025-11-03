using System.Collections.Generic;

namespace SpaceWar
{
    public class RenderDef
    {
        public static readonly string WeatherRender = "KLWeatherEffectFeature";
        public static readonly string MapFogRender = "KLMapFogFeature";
        public static readonly string CopyColorFeature = "KLCopyColorFeature";
        public static readonly string CopyDepthFeature = "KLCopyDepthFeature";

        public static Dictionary<string, GameRenderType> RenderClassDict = new Dictionary<string, GameRenderType>()
        {
            { WeatherRender, GameRenderType.Weather },
            { MapFogRender, GameRenderType.MapFog },
            { CopyColorFeature, GameRenderType.Color },
            { CopyDepthFeature, GameRenderType.Depth },
        };
    }

    public enum GameRenderType
    {
        /** 无 */
        None = 0,

        /** 天气 */
        Weather = 1,

        /** 雾 */
        MapFog = 2,
        /// <summary>
        /// 颜色
        /// </summary>
        Color=3,
        /// <summary>
        /// 深度
        /// </summary>
        Depth=4,
    }

    public enum WeatherType
    {
        /** 无 */
        None = 0,

        /** 雨天 */
        Rainy = 1,

        /** 雪天 */
        Snowy = 2,

        /** 风沙天 */
        Sandy = 3,
    }
}