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

I've chosen to implement the long term solution here to show what it'd be like using the gem [kaminari](https://github.com/kaminari/kaminari). You can find all the work done in implementing pagintion under the commit tag `KI-1`.

For more info on H12 errors, check out the Heroku documentation here: https://devcenter.heroku.com/articles/error-codes#h12-request-timeout

# Notes on Known Issue #2

Heroku delegates the responsibility of redirecting to SSL (or HTTPS) at the application level. This means there's no "magic" setting or button on Heroku to presss that does this. Since we're using a Rails application, we'll need to make that change at the `config/production.rb` level via:

```ruby
config.force_ssl = true
```

Please note that the `config/production.rb` change is unique to what we're doing with our app. If you want SSL at other app stages on Heroku, we'll need to update those files to force ssl as well.

Source: https://help.heroku.com/J2R1S4T8/can-heroku-force-an-application-to-use-ssl-tls

# Notes on Known Issue #3

In our Application Layout file (`application.html.erb`), there's an issue with our logo showing up locally _and_ on Heroku. So, let's start on the local aspect of things and then do work to ensure it holds up on Heroku, if necessary.

Initially, we find this piece of code in our layout:

```
<header>
  <img src="logo.jpg" />
</header>
```

First thing we want to check is: "Do I have an asset called `logo.jpg`? Looking at our `assets/images` folder, we do. This is great news! So, all we have to do is change the syntax of how we're calling our image. In Rails, its considered best practice to use the `image_tag` helper. You can read more about the helper [here](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html). 

Instead of listing "logo.jpg", we'll change it to the following:

```
<header>
  <%= image_tag "logo.jpg" %>
</header>
```

This essentially tells Rails to look in the `assets/images` folder and find an image titled "logo.jpg". The [Asset Pipeline](https://guides.rubyonrails.org/asset_pipeline.html) then delivers the asset and helps us render it on the webpage.

# Notes on Known Issue #4

While every CSS processing library has their own way of dealing with importing, `sass-rails` has a pretty straightfoward way of dealing with imports.

Notice in your `application.css`, there's a comment block at the top that looks something like this:

```css
/*
 *= require_self
 */
```

Its missing one line that allows the Asset Pipeline (and our SASS processor) to take all of the css files under the `app/assets/stylesheets` directory and compile it into one CSS manifest. That line is:

```css
 /*
 *= require_tree
 */
```

Adding `require_tree` to our comment block at the top will fix the issue. You'll find that not only `scaffolds.css` will be imported but also any future stylesheet you include in the `app/assets/stylesheets` folder.

# Notes of Known Issue #5

One of two things is happening here: Either we aren't looking at the right logs in Heroku or our application isn't configured to log as much information as we expect in our `production` environment (or whatever environment we're using on Heroku).

We'll look at our production log configuration first. We can find this config in `config/environments/production.rb` file. It looks like we're using the lowest level available (or most detailed level) per the [Rails guides](https://guides.rubyonrails.org/debugging_rails_applications.html#log-levels):

```ruby
config.log_level = :debug
```

Looks good locally, so let's move on to looking at Heroku. I look at my app logs by running: `heroku logs --source app --tail` and find that not much changes with the output on each request. I'm seeing the boot up and deployment logs but not really anything beyond that. Looks like a bit more research is required.

After some internet snooping, I came across a Heroku [article](https://devcenter.heroku.com/articles/rails4) about Rails 4 and logging on Heroku. I remember one of the things that stood out to me about my heroku deployment output was how I didn't have `rails_12factor` installed and how that was going to limit a lot of the insights and features I could leverage. Let's try that.

After deployment, we find that installing `rails_12factor` was the correct solution. Our logs now output as expected.

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

# October 13 2018

### Spicing Up CSS for Logo

Since the logo comes out of the box as-is, I decided to take the liberty to add a few rules to restrain the size of it and center it at the top.

### Adding a Link to Main Image

I found it kind of annoying to navigate around the app without a means to get back to the "root" or home path of the app. So, I added in a quick link to make moving around the app a bit easier. 

### JS error in the layout

When I patched the issue with Rails logging on Heroku, I noticed an error that was constantly occuring in the logs:

```
0-14T01:46:09.902177+00:00 app[web.1]: ActionController::RoutingError (No route matches [GET] "/javascripts/scaffolds.js"):
2018-10-14T01:46:09.902179+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/actionpack-4.2.10/lib/action_dispatch/middleware/debug_exceptions.rb:21:in `call'
2018-10-14T01:46:09.902181+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/actionpack-4.2.10/lib/action_dispatch/middleware/show_exceptions.rb:30:in `call'
2018-10-14T01:46:09.902182+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/railties-4.2.10/lib/rails/rack/logger.rb:38:in `call_app'
2018-10-14T01:46:09.902184+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/railties-4.2.10/lib/rails/rack/logger.rb:20:in `block in call'
2018-10-14T01:46:09.902186+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/activesupport-4.2.10/lib/active_support/tagged_logging.rb:68:in `block in tagged'
2018-10-14T01:46:09.902188+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/activesupport-4.2.10/lib/active_support/tagged_logging.rb:26:in `tagged'
2018-10-14T01:46:09.902190+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/activesupport-4.2.10/lib/active_support/tagged_logging.rb:68:in `tagged'
2018-10-14T01:46:09.902191+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/railties-4.2.10/lib/rails/rack/logger.rb:20:in `call'
2018-10-14T01:46:09.902193+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/actionpack-4.2.10/lib/action_dispatch/middleware/request_id.rb:21:in `call'
2018-10-14T01:46:09.902194+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/rack-1.6.10/lib/rack/methodoverride.rb:22:in `call'
2018-10-14T01:46:09.902197+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/rack-1.6.10/lib/rack/runtime.rb:18:in `call'
2018-10-14T01:46:09.902198+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/activesupport-4.2.10/lib/active_support/cache/strategy/local_cache_middleware.rb:28:in `call'
2018-10-14T01:46:09.902200+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/actionpack-4.2.10/lib/action_dispatch/middleware/static.rb:120:in `call'
2018-10-14T01:46:09.902206+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/rack-1.6.10/lib/rack/sendfile.rb:113:in `call'
2018-10-14T01:46:09.902208+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/actionpack-4.2.10/lib/action_dispatch/middleware/ssl.rb:24:in `call'
2018-10-14T01:46:09.902210+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/railties-4.2.10/lib/rails/engine.rb:518:in `call'
2018-10-14T01:46:09.902212+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/railties-4.2.10/lib/rails/application.rb:165:in `call'
2018-10-14T01:46:09.902214+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/rack-1.6.10/lib/rack/lock.rb:17:in `call'
2018-10-14T01:46:09.902215+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/rack-1.6.10/lib/rack/content_length.rb:15:in `call'
2018-10-14T01:46:09.902217+00:00 app[web.1]: vendor/bundle/ruby/2.4.0/gems/rack-1.6.10/lib/rack/handler/webrick.rb:88:in `service'
2018-10-14T01:46:09.902219+00:00 app[web.1]: vendor/ruby-2.4.0/lib/ruby/2.4.0/webrick/httpserver.rb:140:in `service'
2018-10-14T01:46:09.902220+00:00 app[web.1]: vendor/ruby-2.4.0/lib/ruby/2.4.0/webrick/httpserver.rb:96:in `run'
2018-10-14T01:46:09.902222+00:00 app[web.1]: vendor/ruby-2.4.0/lib/ruby/2.4.0/webrick/server.rb:290:in `block in start_thread`
```

Looking around the app, I found the following javascript include tag at the top of the application:

```
<%= javascript_include_tag 'application', 'scaffolds' %>
```

Seems kind of weird considering we don't have any `scaffolds` javascript. We do have a sass file named `scaffolds.scss` but it has no relation to our javascript. I've patched this to not include the `scaffolds` tag for the time being, chalking it up on confusion around how to include `scaffolds.scss` since that was a known issue.

### Mystery Man

Found an issue in `app/views/posts/show.html.erb` where we were trying to include an image manually. While the image showed up, we weren't really utilizing the Asset Pipeline to the best of our ability. So I decided to use `image_tag`.