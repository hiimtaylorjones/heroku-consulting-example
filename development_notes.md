# Known Issues

  * [KI-1]. I'm seeing a lot of H12 errors on my app. Someone said something about "concurrency"? Not sure what that is or how to fix my app.
  * [KI-2]. I don't want my app being accessible via http. Is there a way I can force all requests to https?
  * [KI-3]. I can't seem to get my logo.jpg to work in my application layout. Any ideas?
  * [KI-4]. I'm trying to include `scaffolds.scss` in the project, but it's not loading.
  * [KI-5]. When I check my logs on Heroku, I don't see any output from Rails.
  * [KI-6]. My main index page that lists all the posts is really slow and has a ton of DB queries. What's going on here?
  * [KI-7]. I added this awesome feature to email me a post. Example: http://localhost:3000/emails/new?post_id=66  But when I submit the form, it's kind of slow. Any ideas on how I can speed this up?

# Notes on Known Issue #1

Heroku offers a variety of errors to better inform users around what's happening in their application. The error that's specifically being referenced (H12) is one that's triggered when your HTTP request takes longer than 30 seconds to complete on your Heroku instance or instances. So, while it may not take 30 seconds to complete locally, its happening on Heroku and triggering that error.

Looking at your application, I'm seeing a lots of usage of `.all` being called on most of the models on your `#GET Index` endpoints. When we work with smaller data sets, this implementation performs without much of a drag on request times. However, when we scale up to larger data sets (think 1000 vs 50), retreiving 1000 records from smaller Heroku instances can trigger an H12 error. Luckily, there are a few things we can do to prevent this.

I can provide two important short and long term reccomendations based around this finding.

Short Term: 

Use a limit to your index calls. You can do the following:

```ruby
# Grab 25 comments
Comment.all.limit(25)
# Grab the 25 most recent comments
Comment.order(created_at: :desc).limit(25)
```

Long Term:

Use a pagination library to add the ability to sort your larger sets of data into easily digestable pages. Then add some UI elements to help users sort through each page of resources instead of trying to fetch the entire `.all` of a resource. 

I've chosen to implement the long term solution here to show what it'd be like using the gem [kaminari](https://github.com/kaminari/kaminari). You can find all the work done in implementing pagintion under the commit tag `KI-1`.

For more info on H12 errors, check out the Heroku documentation here: https://devcenter.heroku.com/articles/error-codes#h12-request-timeout

Heroku also has a helpful article on general approaches towards H12 errors: https://help.heroku.com/PFSOIDTR/why-am-i-seeing-h12-request-timeouts-high-response-times-in-my-app

## A Few Notes on Finding Performance Issues

Our Posts index sticks out as the area that needs the most attention right now. However, that's not to say that other parts of our application might suffer from similar performance issues down the road. I usually look at three general steps when diagnosing an issue:

1. When I click my way through and interact with a feature, what triggers a slowdown? Is it a page load? Or does clicking a button cause some sort of drag? What's causing the performance drag from a user perspective can help us nail down where to look.
2. Look at your Rails logs. More specifically, what kind of database queries are happening? Is it one giant query that's waiting awhile before it outputs more information? Or is it a fury of a bunch of singular resources being loaded at once? If the query hangs, we're probably trying to fetch something that's too big. If there's a fury of queries, we're probably hitting the database too many times.
3. Look at the ActiveRecord queries being called during a controller endpoint. Would any of those be suspect to causing a slowdown? For example, I knew that `Post.all` was the offender right away because I know that it tries to fetch _every_ `Post` record we had. So, it confirmed my suspicion that the P12 errors were rooted in using queries like that.

## A Few Notes of Concurrency and Ruby

If your initial problem description, you mentioned concurrency as a possibility for solving H12 errors. Concurrency is a great way to handle a heavy workload of code by splitting it up into separate CPU threads to be executed. This is a great approach to handling more dense blocks of code, but it can be a bit tricky or risky. Ruby and Rails in particular have a reputation for not being able to handle concurrent code in the best way possible. However, it can still be really effective if you give it the right amount of work and attention. I would reccomend making something concurrent after optimizing the ActiveRecord or Ruby portion of the slow parts of your app. If you still find it slow after refactoring your code block into the best possible version of itself, concurrency is a great next step to start with.

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

```html
<header>
  <img src="logo.jpg" />
</header>
```

First thing we want to check is: "Do I have an asset called `logo.jpg`? Looking at our `assets/images` folder, we do. This is great news! So, all we have to do is change the syntax of how we're calling our image. In Rails, its considered best practice to use the `image_tag` helper. You can read more about the helper [here](https://api.rubyonrails.org/classes/ActionView/Helpers/AssetTagHelper.html). 

Instead of listing "logo.jpg", we'll change it to the following:

```html
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

# Notes on Known Issue #5

One of two things is happening here: Either we aren't looking at the right logs in Heroku or our application isn't configured to log as much information as we expect in our `production` environment (or whatever environment we're using on Heroku).

We'll look at our production log configuration first. We can find this config in `config/environments/production.rb` file. It looks like we're using the lowest level available (or most detailed level) per the [Rails guides](https://guides.rubyonrails.org/debugging_rails_applications.html#log-levels):

```ruby
config.log_level = :debug
```

Looks good locally, so let's move on to looking at Heroku. I look at my app logs by running: `heroku logs --source app --tail` and find that not much changes with the output on each request. I'm seeing the boot up and deployment logs but not really anything beyond that. Looks like a bit more research is required.

After some internet snooping, I came across a Heroku [article](https://devcenter.heroku.com/articles/rails4) about Rails 4 and logging on Heroku. I remember one of the things that stood out to me about my heroku deployment output was how I didn't have `rails_12factor` installed and how that was going to limit a lot of the insights and features I could leverage. Let's try that.

After deployment, we find that installing `rails_12factor` was the correct solution. Our logs now output as expected. After a bit of poking around on `rails_12factor`'s docs I found [the reason](https://github.com/heroku/rails_12factor#rails-4-logging) why it fixes our issue - besides the fact that Heroku has a doc that reccomends it. 

## Notes on Known Issue #6

Earlier in this project, during fixing Known Issue #1, we encountered a few ideas around how to find and debug performance issues. In the case of that issue, we simply fixed an ActiveRecord call and implemented pagination. But what about the deeper issues of performance? We were able to patch the issues of performance in terms of load times, but what about the numerous queries we're seeing?

Rails, like many frameworks, has this notition of including resources through `has_many` and `belongs_to` relationships. For example, if I load up an endpoint with `@posts = Post.all.limit(25)`, that's one general query. But then in our view, we reference the author of a post object. It ends up generating Rails logs that look something like this:

```
Processing by PostsController#index as HTML
  Post Load (47.2ms)  SELECT  "posts".* FROM "posts" LIMIT 25 OFFSET 0
  Author Load (34.4ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 53]]
  Author Load (0.5ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 38]]
  Author Load (0.2ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 10]]
  Author Load (0.3ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 61]]
  Author Load (0.3ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 13]]
  Author Load (0.2ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 34]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 14]]
  CACHE (0.0ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 14]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 70]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 57]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 62]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 19]]
  Author Load (0.3ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 77]]
  Author Load (0.3ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 65]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 73]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 51]]
  Author Load (0.2ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 16]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 31]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 29]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 41]]
  CACHE (0.0ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 19]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 36]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 80]]
  Author Load (0.1ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 11]]
  CACHE (0.0ms)  SELECT  "authors".* FROM "authors" WHERE "authors"."id" = $1 LIMIT 1  [["id", 29]]
   (6.5ms)  SELECT COUNT(*) FROM "posts"
```

Now, these `Author` load times are on average around `0.1ms` each. Not too harmful right? Well, they're not harmful at the moment but they will weigh down your application in the future as the cost of that database call increases. We want a solution that will allow us to significantly cut down on the amount of database calls we're making. Luckily for us, ActiveRecord has a pretty cool method called [`includes`](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations) that allows us to specify a relationship and have that data included back in the base payload of what we're calling. So, the size of the data we're getting stays the same but we're making a lot less database calls to get it! 

We can do this with our posts index by changing:

```ruby
@posts = Post.all.page(params[:page])
```

Into:

```ruby
@posts = Post.includes(:author).all.page(params[:page])
```

This gives us a Rails logger output of:


```
Processing by PostsController#index as HTML
  Post Load (0.4ms)  SELECT  "posts".* FROM "posts" LIMIT 25 OFFSET 0
  Author Load (43.7ms)  SELECT "authors".* FROM "authors" WHERE "authors"."id" IN (53, 38, 10, 61, 13, 34, 14, 70, 57, 62, 19, 77, 65, 73, 51, 16, 31, 29, 41, 36, 80, 11)
   (0.5ms)  SELECT COUNT(*) FROM "posts"
  Rendered posts/index.html.erb within layouts/appli
```


## Notes on Known Issue #7

### The Error

In testing out the mailer process on Heroku, I get a 500 error that displays the following:

```shell
2018-10-14T02:25:28.664449+00:00 app[web.1]: PostMailer#create: processed outbound mail in 374.1ms
2018-10-14T02:25:28.665456+00:00 app[web.1]: Completed 500 Internal Server Error in 380ms (ActiveRecord: 1.3ms)
2018-10-14T02:25:28.666397+00:00 app[web.1]:
2018-10-14T02:25:28.666399+00:00 app[web.1]: Errno::ECONNREFUSED (Connection refused - connect(2) for "localhost" port 25):
2018-10-14T02:25:28.666401+00:00 app[web.1]: app/controllers/emails_controller.rb:10:in `create'
```

Running this locally yields the same results. So, what's the deal with the Port Connection Issue?

### The Solution

For one, using `deliver_now` or `deliver_later` instead of `deliver!` works locally without error. For reasons I'll explain bellow, we should be using `deliver_later` because of its usage of `ActiveJob`.

What's the reason behind this?

Looking at the [source code](https://github.com/mikel/mail/blob/master/lib/mail/message.rb#L261) for our `deliver!` method, we find that it bypasses a lot of checks and errors diagnostic information that our Mail library gives us. Looking at [Rails' documentation on ActionMailer](https://guides.rubyonrails.org/action_mailer_basics.html#calling-the-mailer), we find that we should be using one of two methods for delivering mail: `deliver_now` or `deliver_later`.

The difference between these two helps us exposes the problem we were trying to solve in the first place. 

`deliver_now` executes the "sending" of mail inline. What this means is that whatever is calling it won't finish until that mailer has been created and sent. 

`deliver_later` creates the mail instance, but delegates the sending of it to Rails' `ActiveJob` or whatever job processing libraries you're using (like Sidekiq). This allows your application to keep running while some "magic" in the backend handles the sending of the mail without holding up a user from doing anything else. There is a catch to this, though. Rails' documentation explains it pretty well

> Active Job's default behavior is to execute jobs via the :async adapter. So, you can use deliver_later now to send emails asynchronously. Active Job's default adapter runs jobs with an in-process thread pool. It's well-suited for the development/test environments, since it doesn't require any external infrastructure, but it's a poor fit for production since it drops pending jobs on restart. If you need a persistent backend, you will need to use an Active Job adapter that has a persistent backend (Sidekiq, Resque, etc).

In short, `deliver_later` saves us from a mailer call blocking an endpoint or action. If the `deliver_later` fails, it just fails. There's no chance to retry or see what went wrong. It fails and disappears from our Rails app's train of thought. So, it would be highly reccomended that we look into using something like `Sidekiq` or `Resque` for our applicaiton.

With this bit of performance mystery dissected, there's still a bit of work that we need to do to our Heroku application to help it send mail in production.

### Setting Heroku Up for Sending Emails

After taking a look at the email settings in each enviornment, there's also a need to configure our Heroku `production` environment to properly send emails. Heroku offers a variety of addons to help us do this, but I want to implement this with Sendgrid.

First up, we need to install this on Heroku:

```shell
heroku addons:create sendgrid:starter
```

This will trigger a process that will automatically setup the Sendgrid AddOn on our Heroku app. It will also create us Sendgrid credentials (listed in the app as `SENDGRID_USERNAME` and `SENDGRID_PASSWORD`). 

With that setup, we can go ahead and install the `sendgrid-ruby` gem in the `production` group in our `Gemfile`. This will give us the ability to communicate with SendGrid

We'll then add the following code to our `config/environments/production.rb`:

```ruby
# Setup the mailer config
config.action_mailer.delivery_method = :smtp
config.action_mailer.perform_deliveries = true
config.action_mailer.smtp_settings = {
  :user_name => ENV['SENDGRID_USERNAME'],
  :password => ENV['SENDGRID_PASSWORD'],
  :domain => 'taylor-jones-heroku-interview.herokuapp.com', 
  :address => 'smtp.sendgrid.net',
  :port => 587,
  :authentication => :plain,
  :enable_starttls_auto => true
}
```

Since we have those variables in our Heroku app, we should be good to go! Upon execution, you should now find that your Heroku app is sending emails from SendGrid! 


### Resources

* [SendGrid AddOn](https://elements.heroku.com/addons/sendgrid)
* [SendGrid Tutorial](https://devcenter.heroku.com/articles/sendgrid)

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

# October 14 2018

### Deleting Some Posts

Due to constriants by Postgres' Free Tier, I needed to delete some of the records in my database. I deleted a hundred or so posts to help meet this limit. Most of the findings and solutions I have made should still be relevent despite the lighter database workload for the application.

# October 16 2018

### Running Tests and Patching Our Rails Instance

While it wasn't one of the requirements, I was curious about whether the test suite had any real coverage
at all. So, I started to run the tests locally and was immediately hit with this error:

```
ActiveRecord::StatementInvalid: PG::UndefinedColumn: ERROR:  column "increment_by" does not exist
LINE 1: ...osts_id_seq"', (SELECT COALESCE(MAX("id")+(SELECT increment_...
```

My initial suspicion was that it was related to the version of Postgres I was running locally. Turns out I was running the same version that's running on Heroku (10.5). So I started to look around for a way to bypass this. 

First, I came across a long-standing [Rails issue](https://github.com/rails/rails/issues/28780) on the matter. There was a few monkeypatches for the issue offered by various users, but I was curious if there were any other options out there.

Next, I came across a [Heroku article](https://help.heroku.com/WKJ027JH/rails-error-after-upgrading-to-postgres-10) that seemed to imply there were three acceptable ways to handle this:

1. Upgrade to Rails 5
2. Use one the [monkeypaches](https://github.com/rails/rails/issues/28780#issuecomment-354868174) in the issue referenced above
3. Change from Postgres 10.5 to Postgres 6

While all of these are great, I chose to use the monkeypatch since I didn't want to rock the boat around the Rails or Postgres version this late in the project. With the patch in place, I finally had results from the test suite. 

While a lot of test coverage was valid and in place for the application, many tests were out of date or not needed at all. So, I cleaned up and fixed the test suite.

Two files, `test/controllers/posts_controller_test.rb` and `test/mailers/post_mailer_test.rb` needed to have test cases fixed. I commented out `test/controllers/comments_controller_test.rb` because its routes were never included within the `config/routes.rb` file of our application. I want to leave that up to the client to decide whether or not they want to include that functionality or delete it alltogether.