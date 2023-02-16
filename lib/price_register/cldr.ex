defmodule PriceRegister.Cldr do
  use Cldr,
    default_locale: "en",
    json_library: Jason,
    locales: ["en"],
    gettext: PriceRegister.Gettext,
    data_dir: "./priv/cldr",
    otp_app: :price_register,
    providers: [Cldr.Number],
    generate_docs: true
end
