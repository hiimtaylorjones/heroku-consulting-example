# About This Project

This project shows how I would address fixing known issues (as well as discovering hidden) issues with
a Rails application hosted on Heroku. The application is a basic blog that has the ability to manage 
posts as well as share them with others via email.

## Local Setup

```bash
bundle
rake db:create 
rake db:migrate
rake db:seed
```

You can then run the application via:

```shell
rails s
```

## Resources

* You can find notes on the devlopment and resolution of issues [here](development_notes.md)
