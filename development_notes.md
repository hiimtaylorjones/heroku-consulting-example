# Known Issues

  1. I'm seeing a lot of H12 errors on my app. Someone said something about "concurrency"? Not sure what that is or how to fix my app.
  2. I don't want my app being accessible via http. Is there a way I can force all requests to https?
  3. I can't seem to get my logo.jpg to work in my application layout. Any ideas?
  4. I'm trying to include `scaffolds.scss` in the project, but it's not loading.
  5. When I check my logs on Heroku, I don't see any output from Rails.
  6. My main index page that lists all the posts is really slow and has a ton of DB queries. What's going on here?
  7. I added this awesome feature to email me a post. Example: http://localhost:3000/emails/new?post_id=66  But when I submit the form, it's kind of slow. Any ideas on how I can speed this up?

# October 12 2018

* In order to make things compile properly, I had to deleted the `Gemfile.lock` and 
  run `bundle` again.