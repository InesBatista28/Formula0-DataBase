using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;

namespace ProjetoFBD
{
    public static class FlagHelper
    {
        private static readonly Dictionary<string, string> CountryToIso2 = new(StringComparer.OrdinalIgnoreCase)
        {
            {"Portugal","pt"},
            {"Spain","es"}, {"Espanha","es"},
            {"Italy","it"}, {"Itália","it"},
            {"France","fr"}, {"França","fr"},
            {"United Kingdom","gb"}, {"UK","gb"}, {"Reino Unido","gb"},
            {"Belgium","be"}, {"Bélgica","be"},
            {"Netherlands","nl"}, {"Holanda","nl"},
            {"Germany","de"}, {"Alemanha","de"},
            {"Austria","at"}, {"Áustria","at"},
            {"Monaco","mc"}, {"Mónaco","mc"},
            {"Hungary","hu"}, {"Hungria","hu"},
            {"Brazil","br"}, {"Brasil","br"},
            {"United States","us"}, {"USA","us"}, {"Estados Unidos","us"},
            {"Mexico","mx"}, {"México","mx"},
            {"Canada","ca"}, {"Canadá","ca"},
            {"Japan","jp"}, {"Japão","jp"},
            {"Singapore","sg"}, {"Singapura","sg"},
            {"Australia","au"}, {"Austrália","au"},
            {"United Arab Emirates","ae"}, {"UAE","ae"}, {"Emirados Árabes","ae"},
            {"Bahrain","bh"}, {"Bahrein","bh"},
            {"Saudi Arabia","sa"}, {"Arábia Saudita","sa"},
            {"Qatar","qa"}, {"Catar","qa"},
            {"China","cn"},
            {"South Korea","kr"}, {"Coreia do Sul","kr"},
            {"Russia","ru"}, {"Rússia","ru"},
            {"Azerbaijan","az"}, {"Azerbaijão","az"},
            {"Turkey","tr"}, {"Turquia","tr"}
        };

        private static readonly Dictionary<string, Image> Cache = new(StringComparer.OrdinalIgnoreCase);

        public static Image? GetFlagImageFromCountry(string? countryName)
        {
            string key = (countryName ?? string.Empty).Trim();
            if (string.IsNullOrEmpty(key)) return null;

            // Remove a eventual bandeira que possa vir prefixada (ex: "🇵🇹 Portugal")
            key = RemoveEmojiPrefix(key);

            if (!CountryToIso2.TryGetValue(key, out var iso))
            {
                // Tentar quando o campo traz iniciais tipo "PT", "ES"
                if (key.Length == 2)
                    iso = key.ToLowerInvariant();
                else
                    return null;
            }

            if (Cache.TryGetValue(iso, out var imgCached))
                return imgCached;

            try
            {
                // Procurar em IMPLEMENTAÇÃO/flags/<iso>.png (relativo ao executável)
                string rel = Path.Combine("..", "..", "..", "flags", iso + ".png");
                string full = Path.GetFullPath(Path.Combine(System.Windows.Forms.Application.StartupPath, rel));
                if (File.Exists(full))
                {
                    using var fs = new FileStream(full, FileMode.Open, FileAccess.Read, FileShare.Read);
                    var img = Image.FromStream(fs);
                    Cache[iso] = img;
                    return img;
                }
            }
            catch { }

            return null;
        }

        private static string RemoveEmojiPrefix(string text)
        {
            if (string.IsNullOrEmpty(text)) return text;
            // Heuristic: if starts with an emoji flag + space, drop first 3-5 chars until first letter/digit
            int i = 0;
            while (i < text.Length && char.IsSurrogate(text[i])) i++;
            // Trim leading symbols/emojis
            return text.TrimStart(' ', '\t', '\uFE0F', '\u200D', '\u2060', '\u2066', '\u2067', '\u2068', '\u2069', '\u00A0', '\u200B', '\u200C');
        }
    }
}
