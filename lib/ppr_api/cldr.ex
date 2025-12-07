defmodule PprApi.Cldr do
  use Cldr,
    otp_app: :ppr_api,
    default_locale: "en",
    locales: ["en"],
    providers: [Cldr.Number]
end
