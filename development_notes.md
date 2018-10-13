# Known Issues

  1. I'm seeing a lot of H12 errors on my app. Someone said something about "concurrency"? Not sure what that is or how to fix my app.
  2. I don't want my app being accessible via http. Is there a way I can force all requests to https?
  3. I can't seem to get my logo.jpg to work in my application layout. Any ideas?
  4. I'm trying to include `scaffolds.scss` in the project, but it's not loading.
  5. When I check my logs on Heroku, I don't see any output from Rails.
  6. My main index page that lists all the posts is really slow and has a ton of DB queries. What's going on here?
  7. I added this awesome feature to email me a post. Example: http://localhost:3000/emails/new?post_id=66  But when I submit the form, it's kind of slow. Any ideas on how I can speed this up?

# October 12 2018


1. In order to make things compile properly, I had to deleted the `Gemfile.lock` and run `bundle` again.

2. There's a lot of issues around deploying the application to Heroku out of the box. After a bit of research, I found that the following issues was happening when I ran `rake assets:precompile` locally _and_ on Heroku:

```
/Users/tjones/.rvm/gems/ruby-2.4.0/gems/activesupport-4.2.7.1/lib/active_support/core_ext/numeric/conversions.rb:131:in `block (2 levels) in <class:Numeric>'
/Users/tjones/.rvm/gems/ruby-2.4.0/gems/activesupport-4.2.7.1/lib/active_support/core_ext/numeric/conversions.rb:131:in `block (2 levels) in <class:Numeric>'
/Users/tjones/.rvm/gems/ruby-2.4.0/gems/activesupport-4.2.7.1/lib/active_support/core_ext/numeric/conversions.rb:131:in `block (2 levels) in <class:Numeric>'
/Users/tjones/.rvm/gems/ruby-2.4.0/gems/activesupport-4.2.7.1/lib/active_support/core_ext/numeric/conversions.rb:131:in `block (2 levels) in <class:Numeric>'
```

Turns out there's an ongoing dicussions around this going on in the Rails project: https://github.com/rails/rails/issues/25125

I ultimately opted for a solution that involves bumping Rails up a bit: https://github.com/rails/rails/issues/25125#issuecomment-364135113

