# Amazon Mobile Analytics Event Reporter for Rails

This gem provide a simple way to report analytics events to Amazon Mobile Analytics from your Rails Server.

## Installation

Install the latest stable release:

```
$ gem install awsma_rails https://github.com/teamapp/aws-mobileanalytics-rails.git
```

In Rails, add it to your Gemfile:

```ruby
gem 'awsma_rails', :git => 'https://github.com/teamapp/aws-mobileanalytics-rails.git'
```

Finally, restart the server to apply the changes.


## Getting Started

Start off by creating an Amazon Mobile Analytics event reporter:

```ruby

# THE AMAZON MOBILE ANALYTICS EVENT URL
# NOTE: MAYBE SET IT IN AN ENVIRONMENT VARIABLE AS WELL
aws_mobile_anlaytics_url = 'https://mobileanalytics.us-east-1.amazonaws.com/2014-06-05/events'

# YOUR AMAZON MOBILE ANALYTICS APP ID
aws_mobile_analytics_app_id = ENV['AWS_MOBILE_ANALYTICS_APP_ID']

# YOUR AMAZON MOBILE ANALYTICS COGNITO POOL
aws_mobile_analytics_identity_pool = ENV['AWS_MOBILE_ANALYTICS_IDENTITY_POOL_ID']

reporter =  AwsmaRails::Reporter.new(aws_mobile_anlaytics_url,
                                     aws_mobile_analytics_app_id,
                                     aws_mobile_analytics_identity_pool)
```

You can then you the create `reporter` object to send event to Amazon Mobile Analytics:

```ruby

# YOUR USER'S ID
client_id = ..

 # YOUR USERS SESSION ID OR USE 'no-session' IF THE EVENT IS NOT DIRECTLY RELATED TO ANY SESSION (FOR EXAMPLE: A PUSH NOTIFICATION)
session_id = ..

# YOUR APP TITLE
app_title = ..

# YOUR APP PACKAGE NAME, USUALLY IN THE FOLLOWING FORMAT: com.your.brand.name
app_package_name = ..

# THE EVENT NAME
event_name = ..

# THE PLATFORM OF THE DEVICE: android, iOS, linux
platform = ..

# THE PLATFORM MODEL OF THE DEVICE 
model = ..

# THE EVENT NAME
event_name = ..

# A HASH THAT CONTAINS THE EVENT ATTRIBUTES: Key-value pair
attributes = ..

# A HASH THAT CONTAINS THE EVENT METRICS: Key-value pair
metrics = ..

# FOR SINGLE EVENT
reporter.report_event(client_id, session_id, app_title,
                      app_package_name, event_name, 
                      platform, model, 
                      attributes, metrics)


# FOR MULTIPLE EVENTS
events = [{
  'event_name': event_name,
  'session_id': session_id,
  'attributes': {},
  'metrics': {}
}, ...]

reporter.report_events(client_id, app_title, app_package_name, 
                       platform, model, events)
```

## License

Copyright (c) 2016 Thumzap

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
