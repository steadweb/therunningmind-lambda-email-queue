// SES
const AWS = require("aws-sdk");
const SES = new AWS.SES({ region: "eu-west-1" });

// Mailgun
const api_key = null;
const domain = "therunningmind.steadweb.com";
const mailgun = require("mailgun-js")({
  apiKey: api_key,
  domain: domain,
  host: "api.eu.mailgun.net"
});

module.exports.ses = async (event, context, callback) => {
  console.log(event.Records);

  for (const record of event.Records) {
    const details = JSON.parse(record.body);

    // Only deal with onboarding / welcome email for the moment
    if (details.type === "welcome") {
      const params = {
        Destination: {
          ToAddresses: [details.email]
        },
        Source: `Elf at Work <hello@elfatwork.com>`,
        SourceArn: "arn:aws:ses:eu-west-1:691650502751:identity/elfatwork.com",
        Template: "Welcome",
        TemplateData: JSON.stringify({
          clientname: "brit",
          uuid: details.uuid
        })
      };

      return await new Promise(resolve => {
        SES.sendTemplatedEmail(params, (err, res) => {
          if (err) {
            throw new Error(err);
          } else {
            console.log(res);
            console.log(`${params.Template} email sent to ${details.email}`);

            resolve({
              statusCode: 200,
              body: JSON.stringify(res)
            });
          }
        });
      });
    }
  }
};

module.exports.mailgun = async (event, context, callback) => {
  console.log(event.Records);

  for (const record of event.Records) {
    const details = JSON.parse(record.body);

    const data = {
      from: "Elf at Work <no-reply@halo-pulse.steadweb.com>",
      to: details.email,
      subject: "Password Reset",
      text: details.uuid
    };

    console.log("Attempting to send email with mailgun");

    return await new Promise(resolve => {
      console.log("Inside promise for sending email");

      mailgun.messages().send(data, function (error, body) {
        console.log("Inside callback for sending mail");
        console.log(body);

        if (error) {
          throw new Error(error);
        }

        resolve({
          statusCode: 200,
          body: JSON.stringify(body)
        });
      });
    });
  }
};
