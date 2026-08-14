using System.Security.Cryptography;
using SPORTSGURUKUL.Application.Coaches.Interfaces;

namespace SPORTSGURUKUL.Infrastructure.Security;

public class TemporaryPasswordGenerator : ITemporaryPasswordGenerator
{
    private const string Uppercase = "ABCDEFGHJKLMNPQRSTUVWXYZ";
    private const string Lowercase = "abcdefghijkmnopqrstuvwxyz";
    private const string Digits = "23456789";
    private const string Symbols = "!@#$%^&*";

    public string Generate()
    {
        var all = Uppercase + Lowercase + Digits + Symbols;
        var chars = new char[12];

        chars[0] = Pick(Uppercase);
        chars[1] = Pick(Uppercase);
        chars[2] = Pick(Lowercase);
        chars[3] = Pick(Lowercase);
        chars[4] = Pick(Digits);
        chars[5] = Pick(Digits);
        chars[6] = Pick(Symbols);

        for (var i = 7; i < chars.Length; i++)
        {
            chars[i] = Pick(all);
        }

        Shuffle(chars);

        return new string(chars);
    }

    private static char Pick(string alphabet)
        => alphabet[RandomNumberGenerator.GetInt32(alphabet.Length)];

    private static void Shuffle(char[] values)
    {
        for (var i = values.Length - 1; i > 0; i--)
        {
            var j = RandomNumberGenerator.GetInt32(i + 1);
            (values[i], values[j]) = (values[j], values[i]);
        }
    }
}
