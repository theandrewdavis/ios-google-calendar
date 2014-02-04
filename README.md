This is a toy iOS app demonstrating downloading, storing, and displaying a public Google calendar. Google has a lot of documentation about connecting to private calendars using OAuth but getting a public calendar as JSON was surprisingly hard to figure out.

For this demo, I'm tracking the US Federal Holidays calendar. I downloaded the iCal file from [opm.gov](http://www.opm.gov/about-us/open-government/Data/Apps/Holidays/Index.aspx) and imported it into a public calendar on my Google account. Here's a screenshot of the finished result: ![alt tag](http://upload.wikimedia.org/wikipedia/commons/f/fc/Emu-wild.jpg).

### How it works
To display a public calendar, you can use a single HTTP request and skip Google's SDK. You'll still need an API key, though. Log in to the [Google API Console](https://cloud.google.com/console/project) and create a project. Click on your project, then "APIs and auth" and turn on "Calendar API". Under "Credentials" then "Public API access", create a new server key (iOS keys don't seem to be supported for the Calendar API). Don't add any IP addresses so that any user of your app can connect to the calendar.

More information on Google's API keys is [here](https://developers.google.com/console/help/new/#usingkeys). I've embedded my server API key in the iOS app, which Google has warned me not to do. This is not ideal since it means that someone could take the key and use it to make a bunch of API calls, exhausting the [courtesy usage limit](https://developers.google.com/google-apps/calendar/pricing) of 100,000 requests per day. A more secure solution would be to host a web service that polls the public Google calendar and serves it to iOS clients, meaning the server key could remain secret. For this case I'm willing to accept the risk in exchange for a much simpler implementation.

You'll also need your calendar's id. On the left sidebar of your [Google Calendar](https://www.google.com/calendar/render), choose the calendar you want to subscribe to and select "Calendar settings" then "Share this Calendar" and check "Make this calendar public". Then on the "Calendar Details" tab under "Calendar Address", you should see your calendar id. For this demo, it's *47ou48fasc70l0758i9lh76sr8@group.calendar.google.com*.

Now for some code! This is the HTTP request to get the events on a calendar using [AFNetworking](https://github.com/AFNetworking/AFNetworking). Just plug in your calendar id and API key.

````Objective-C
- (void)updateCalendar {
    NSString *calendarId = @"47ou48fasc70l0758i9lh76sr8@group.calendar.google.com";
    NSString *apiKey = @"AIzaSyCAkVQVwMzmPHxbaLUAqvb6dYUwjKU5qnM";
    NSString *urlFormat = @"https://www.googleapis.com/calendar/v3/calendars/%@/events?key=%@&fields=items(id,start,summary,status)";
    NSString *calendarUrl = [NSString stringWithFormat:urlFormat, calendarId, apiKey];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:calendarUrl parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        // HTTP request succeeded!
        for (NSDictionary *eventData in responseObject[@"items"]) {
            NSLog(@"%@", eventData[@"summary"]);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // HTTP request failed!
    }];
}
````

Parsing the dates is a little tricky since they can come as dates or datetimes, Here's a snippet to deal with both:

````Objective-C
static NSDateFormatter *dayFormatter, *timeFormatter;
if (!dayFormatter || !timeFormatter) {
    dayFormatter = [[NSDateFormatter alloc] init];
    dayFormatter.dateFormat = @"yyyy-MM-dd";
    timeFormatter = [[NSDateFormatter alloc] init];
    timeFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
}
for (NSDictionary *eventData in events) {
    NSDate *date;
    if (eventData[@"start"][@"date"]) {
    date = [dayFormatter dateFromString:eventData[@"start"][@"date"]];
    } else if (eventData[@"start"][@"dateTime"]) {
    date = [timeFormatter dateFromString:eventData[@"start"][@"dateTime"]];
    NSLog("%@", date);
}
````
