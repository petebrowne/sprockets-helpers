sprockets-helpers
=================

**Asset path helpers for Sprockets 2.0 applications**

Sprockets::Helpers adds the asset_path helpers, familiar to Rails developers, to Sprockets 2.0 assets and application.

### Features

* Includes image_path, javascript_path, & stylesheet_path helpers.
* Automatically appends extension if necessary.
* Optionally outputs digest paths.
* Falls back to file paths in the public directory.


Installation
------------

``` bash
$ gem install sprockets-helpers
```


Setup
-----

Let's build a simple Sinatra app using Sprockets and Sprockets::Helpers (See [sinatra-asset-pipeline](https://github.com/stevehodgkiss/sinatra-asset-pipeline) for complete setup):

``` ruby
require "sinatra/base"
require "sprockets"
require "sprockets-helpers"

class App < Sinatra::Base
  set :sprockets, Sprockets::Environment.new(root)
  set :assets_prefix, "/assets"
  set :digest_assets, false
  
  configure do
    # Setup Sprockets
    sprockets.append_path File.join(root, "assets", "stylesheets")
    sprockets.append_path File.join(root, "assets", "javascripts")
    sprockets.append_path File.join(root, "assets", "images")
    
    # Configure Sprockets::Helpers (if necessary)
    Sprockets::Helpers.prefix      = assets_prefix
    Sprockets::Helpers.digest      = digest_assets
    Sprockets::Helpers.public_path = public_folder
  end
  
  helpers do
    include Sprockets::Helpers
    
    # required for Sprockets::Helpers to work!
    def environment
      settings.sprockets
    end
  end
  
  get "/" do
    erb :index
  end
end
```


Usage in Assets
---------------

Simply requiring sprockets-helpers will add the asset path helpers to the Sprocket context, making them available within any asset. For example, a file `assets/javascripts/paths.js.erb`:

``` erb
var Paths = { railsImage: "<%= image_path "rails.png %>" };
```

Would be transformed into:

``` javascript
var Paths = { railsImage: "/assets/rails.png" };
```


Usage in the App
----------------

The helpers can also be used in the app itself. You just include the `Sprockets::Helpers` module and add an `#environment` method which returns a reference to the Sprockets environment (see the Sinatra app setup above).

Now the following index file:

``` erb
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Sinatra with Sprockets 2 (Asset Pipeline)</title>
    <link rel="stylesheet" href="<%= stylesheet_path "application" %>">
    <script src="<%= javascript_path "application" %>"></script>
  </head>
  <body>
    <img src="<%= image_path "rails.png" %>">
  </body>
</html>
```

Would become:

``` html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Sinatra with Sprockets 2 (Asset Pipeline)</title>
    <link rel="stylesheet" href="/assets/application.css">
    <script src="/assets/application.js"></script>
  </head>
  <body>
    <img src="/assets/rails.png">
  </body>
</html>
```


Fallback to Public Directory
----------------------------

If the source is not an asset in the Sprockets environment, Sprockets::Helpers will fallback to looking for the file in the application's public directory. It will also append the cache busting timestamp of the file. For example:

Given an image, `public/images/logo.jpg`:

``` erb
<img src="<%= image_path "logo.jpg" %>">
```

Would become:

``` html
<img src="/images/logo.jpg?1320093919">
```


Copyright
---------

Copyright (c) 2011 [Peter Browne](http://petebrowne.com). See LICENSE for details.
