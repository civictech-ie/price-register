# property price register api

This is a thin API layer on top of the CSV data provided by the <a href="https://www.propertypriceregister.ie">Property Services Regulatory Authority</a>. The PSRA&rsquo;s CSVs have some funny encoding (CP1252), a misconfigured SSL certificate, and are generally a bit annoying to query directly. This service queries the CSVs and provides them here with a more standard JSON API. It doesn&rsquo;t do any normalising or cleaning of the address or description fields, so any errors present on the register itself will be present here.

There are a bunch of caveats about the data on the <a href="https://www.propertypriceregister.ie">PSRA&rsquo;s price register site</a>, so look for answers there if you&rsquo;re curious.

The API only covers residential properties. Maybe you want to add commercial properties? <a href="https://www.github.com/civictech-ie/price-register">Go ahead</a>.

I made a public site primarily to illustrate how one might interact with this API. It&rsquo;s generally what you'd expect, I hope. <code>GET /api/v1/residential/sales</code> will return a list of JSON objects.

## development

It's pretty straightforward to run the app yourself. It's a typical [Elixir](https://elixir-lang.org)/[Phoenix](https://www.phoenixframework.org) app that fetches and consumes CSVs from the PSRA.

You'll need Elixir, Erlang and PostgreSQL installed. Versions are in the `.tool-versions` file.

```
git clone https://github.com/civictech-ie/price-register.git
cd price-register
mix deps.get
mix ecto.setup
mix phx.server
```

Now you can visit [`localhost:4000`](http://localhost:4000) and it should be working. It might run a bit hot while it does its initial fetch from the PSRA.

## contributing

If you're interested in contributing, put a note [in the issues](https://github.com/civictech-ie/price-register/issues). And make sure the tests pass (`mix test`).

In general, I'm thinking the scope is: let's make the API a bit better for querying and ordering results. But making the public site more useful for directly accessing the data is out of scope – if you want to do that, just make your own service that consumes this API!
