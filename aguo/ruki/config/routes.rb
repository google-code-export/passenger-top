Wiki::Application.routes.draw do
  base_url = Wiki::Application.config.root_path
  scope base_url do
  #scope "/of" do
    #root :to => ''
    root :to => 'wiki#index'

    resources :projects do
      collection do
        get 'index'
        get 'login'
        post 'login'
        get 'lang'
      end
      resources :wiki do
        #resources :page
        member do
          get 'add'
          get 'page'
          get 'edit'
          post 'edit'
          get 'revisions'
          get 'diff'
          match 'revisions/:rid' => 'wiki#revision_page'
          #get 'export'
          post 'preview'
        end
        collection do
          get 'index'
          get 'list'
          post 'list'
          get 'help'
          #get 'export'
          post 'web_upload'
          get 'files'
          post 'delete_files'
          #will remove below
        end
      end
    end
    #match '/projacts' => 'projacts#index'
    #get "wiki/index"
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
