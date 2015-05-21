## Phoenix.PubSub.Redis

> A Redis PubSub adapter for the Phoenix framework

See the [docs](https://hexdocs.pm/phoenix_pubsub_redis/) for more information.

To use Redis as your PubSub adapter, simply add it to your deps and Endpoint's config:


You will also need to add `:redo` to your deps:


    # mix.exs
    defp deps do
      [{:phoenix_pubsub_redis, "~> 0.0.1"}],
       {:redo, github: "heroku/redo"}]
    end



    # config/config.exs
    config :my_app, MyApp.Endpiont,
    pubsub: [adapter: Phoenix.PubSub.Redis,
                host: "192.168.1.100"]

Config Options

* `:name` - The required name to register the PubSub processes, ie: `MyApp.PubSub`
* `:host` - The redis-server host IP, defaults `"127.0.0.1"`
* `:port` - The redis-server port, defaults `6379`
* `:password` - The redis-server password, defaults `""`


And also add both `:redo` and `:poolboy` to your list of applications:

    def application do
      [mod: {MyApp, []},
       applications: [..., :phoenix, :poolboy]]
    end


## License

Copyright (c) 2014 Chris McCord

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
