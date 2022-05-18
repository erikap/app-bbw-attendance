defmodule Dispatcher do
  use Matcher

  define_accept_types [
    json: [ "application/json", "application/vnd.api+json" ],
    html: [ "text/html", "application/xhtml+html" ],
    any: [ "*/*" ]
  ]

  define_layers [ :static, :services ]

  ## Static frontend resources of all kinds

  get "/favicon.ico", %{ layer: :static } do
    Proxy.forward conn, [], "http://frontend/favicon.ico"
  end

  get "/assets/*path", %{ layer: :static } do
    Proxy.forward conn, path, "http://frontend/assets/"
  end

  get "/torii/redirect.html", %{ layer: :static } do
    Proxy.forward conn, [], "http://frontend/torii/redirect.html"
  end


  ## Resources

  match "/events/*path", %{ layer: :services, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/event/"
  end

  match "/attendances/*path", %{ layer: :services, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/attendances/"
  end

  get "/persons/*path", %{ layer: :services, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://cache/persons/"
  end


  ## Authentication / login

  match "/sessions/*path", %{ layer: :services, accept: %{ json: true } } do
    Proxy.forward conn, path, "http://msal-login/sessions/"
  end


  ## Fallback

  get "/*_path", %{ layer: :services, accept: %{ html: true } } do
    Proxy.forward conn, [], "http://frontend/index.html"
  end

  match "/*_path", %{ last_call: true, accept: %{ json: true } } do
    send_resp( conn, 404, "{ \"error\": { \"code\": 404, \"message\": \"Route not found.  See config/dispatcher.ex\" } }" )
  end

  match "/*_path", %{ last_call: true } do
    send_resp( conn, 404, "Route not found.  See config/dispatcher.ex" )
  end

end
