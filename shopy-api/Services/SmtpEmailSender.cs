using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace shopy_api.Services;

public class SmtpEmailSender(IConfiguration configuration) : IEmailSender
{
    public async Task SendAsync(string toEmail, string subject, string body)
    {
        var section = configuration.GetSection("Email");
        var host = section["SmtpHost"];
        var port = section.GetValue("SmtpPort", 587);
        var username = section["Username"];
        var password = section["Password"];
        var fromName = section["FromName"] ?? "Shopy";

        if (string.IsNullOrEmpty(host) || string.IsNullOrEmpty(username) || string.IsNullOrEmpty(password))
        {
            throw new InvalidOperationException("Konfigurasi Email:SmtpHost/Username/Password belum diisi.");
        }

        var fromEmail = string.IsNullOrEmpty(section["FromEmail"]) ? username : section["FromEmail"]!;

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(fromName, fromEmail));
        message.To.Add(MailboxAddress.Parse(toEmail));
        message.Subject = subject;
        message.Body = new TextPart("plain") { Text = body };

        using var client = new SmtpClient();
        await client.ConnectAsync(host, port, SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(username, password);
        await client.SendAsync(message);
        await client.DisconnectAsync(true);
    }
}
