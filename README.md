# The Running Mind - Email Lamaba

This functionality automates the creation of the `email` SQS queue and `email` Lambda which attaches itself to the queue. Each time a message is sent, the lambda is invoked. `terraform` has been used to automate the creation and setup. State is stored in `S3` and lock is stroed in `DynamoDB`.

## Setup

The run the following commands to start development

```
terraform init
cd lambada
npm i
cd ../
```

## Deployment

Run the following commands to deploy a new version of the lambda

```
terraform apply -auto-approve
```

### Notes

Notes regarding the integration:

- The lambda is designed to handle many messages at one time, but the queue is configured to only pass one message. This is designed by default so that fault tolerance is built in (so that only one message fails during a request)
- `email` and `email-dl` exist for pasring. `email-dl` is for any errors returned by `SES`, which need manual intervention
- Mailgun setup for testing puropses, which can be removed. The default handler is `ses`.
