# Known Issues

  1. I'm seeing a lot of H12 errors on my app. Someone said something about "concurrency"? Not sure what that is or how to fix my app.
  2. I don't want my app being accessible via http. Is there a way I can force all requests to https?
  3. I can't seem to get my logo.jpg to work in my application layout. Any ideas?
  4. I'm trying to include `scaffolds.scss` in the project, but it's not loading.
  5. When I check my logs on Heroku, I don't see any output from Rails.
  6. My main index page that lists all the posts is really slow and has a ton of DB queries. What's going on here?
  7. I added this awesome feature to email me a post. Example: http://localhost:3000/emails/new?post_id=66  But when I submit the form, it's kind of slow. Any ideas on how I can speed this up?

# Notes on Known Issues #1

Heroku offers a variety of errors to better inform users around what's happening in their application. The error that's specifically being referenced (H12) is one that's triggered when your HTTP request takes longer than 30 seconds to complete on your Heroku instance or instances. So, while it may not take 30 seconds to complete locally, its happening on Heroku and triggering that error.

Looking at your application, I'm seeing a lots of usage of `.all` being called on most of the models on your `#GET Index` endpoints. When we work with smaller data sets, this implementation performs without much of a drag on request times. However, when we scale up to larger data sets (think 1000 vs 50), retreiving 1000 records from smaller Heroku instances can trigger an H12 error. Luckily, there are a few things we can do to prevent this.

I can provide two important short and long term reccomendations based around this finding.

Short Term: 

Use a limit to your index calls. You can do the following:

```
# Grab 25 comments
Comment.all.limit(25)
# Grab the 25 most recent comments
Comment.order(:created_at, :desc).limit(25)
```

Long Term:

Use a pagination library to add the ability to sort your larger sets of data into easily digestable pages. Then add some UI elements to help users sort through each page of resources instead of trying to fetch the entire `.all` of a resource. 

For more info on H12 errors, check out the Heroku documentation here: https://devcenter.heroku.com/articles/error-codes#h12-request-timeout

# Development Log

## October 12 2018

### Rake DB Warnings

Getting this warning when running `rake db:` commands:

```
The PGconn, PGresult, and PGError constants are deprecated, and will be
removed as of version 1.0.

You should use PG::Connection, PG::Result, and PG::Error instead, respectively.
```

### Ruby 2.3.3 Is No Longer Supported

Per: https://devcenter.heroku.com/articles/ruby-support#supported-runtimes, Ruby 2.3.3 is no longer supported on Heroku. So, we'll need to bump to 2.4.0.

This leads us to another intersting issue around precompiling our assets. I actually reverted on this change earlier to try using 2.3.3 (since the `.ruby-version` was set to that). But when you try to run `rake assets:precompile` on our application with Ruby 2.4.0, we run into an error that's been ongoing with Rails 2.4.6 - https://github.com/rails/rails/issues/25125. 

There's a few options that we have towards this, but our best bet lies within just bumping our Rails version up a few versions to `~> 2.4.10` - https://github.com/rails/rails/issues/25125

