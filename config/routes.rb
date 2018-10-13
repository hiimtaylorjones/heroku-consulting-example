Rails.application.routes.draw do

  resources :emails, only: [:create, :new]

  resources :authors

  resources :posts do
    resources :comments
  end

  root 'posts#index'

end
