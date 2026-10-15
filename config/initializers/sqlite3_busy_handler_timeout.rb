# Backport de Rails 8: con `timeout:` en database.yml, esperar el lock de escritura
# con busy_handler_timeout (suelta el GVL) en vez de busy_timeout (lo retiene).
#
# Con busy_timeout, mientras una conexión espera el lock ningún otro hilo del
# proceso avanza, ni siquiera el que tiene el lock: en Puma con varios hilos la
# espera dura todo el timeout y termina en SQLite3::BusyException.
#
# Rails 8 ya lo hace así. Borrar este archivo al subir a Rails 8.
module SQLite3BusyHandlerTimeout
  def configure_connection
    super

    @raw_connection.busy_handler_timeout = @config[:timeout] if @config[:timeout]
  end
end

ActiveSupport.on_load(:active_record_sqlite3adapter) do
  prepend SQLite3BusyHandlerTimeout
end
