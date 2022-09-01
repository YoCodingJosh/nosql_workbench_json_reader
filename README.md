This is a piece of something that I made for [@oshiete](https://github.com/oshiete) back in 2021.

License: CC0 (see `LICENSE` for more details)

This takes the JSON output from Amazon's NoSQL Workbench and creates tables using the AWS SDK for Ruby.

Don't forget to set your AWS SDK config (I have provided a basic JSON that points to a local DynamoDB instance):

```
# Set up AWS environment using the details from config.json
  config = JSON.parse(File.read('./config.json'))
  Aws.config.update(
    endpoint: config['endpoint'],
    region: config['region']
  )
```

