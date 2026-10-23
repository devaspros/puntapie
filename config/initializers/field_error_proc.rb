# Por defecto Rails envuelve los campos con errores en un <div class="field_with_errors">,
# que separa el input de su label y rompe los form-floating de Bootstrap. Las vistas ya
# marcan el campo con is-invalid y muestran el mensaje en un invalid-feedback.
ActionView::Base.field_error_proc = proc do |html_tag, _instance|
  html_tag
end
