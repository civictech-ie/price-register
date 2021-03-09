defmodule PriceRegisterWeb.Meta do
  defmacro __before_compile__(_env) do
    quote do
      def metadata(_, _), do: %{}
    end
  end

  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)

      def get_metadata(%{private: %{phoenix_action: action, phoenix_view: view}, assigns: assigns}) do
        Map.merge(
          Application.get_env(:price_register, PriceRegisterWeb.Meta),
          view.metadata(action, assigns)
        )
      end
    end
  end
end
