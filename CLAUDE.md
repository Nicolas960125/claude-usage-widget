# Claude Usage Widget

## Despliegue

Los archivos activos de Quickshell están en `~/.config/quickshell/ii/`, no en este repo.

Después de cada cambio, copiar los archivos modificados:

```bash
cp quickshell/services/ClaudeUsage.qml ~/.config/quickshell/ii/services/ClaudeUsage.qml
cp quickshell/bar/ClaudeBar.qml ~/.config/quickshell/ii/modules/ii/bar/ClaudeBar.qml
cp quickshell/bar/ClaudeUsageMeter.qml ~/.config/quickshell/ii/modules/ii/bar/ClaudeUsageMeter.qml
cp quickshell/bar/ClaudeUsagePopup.qml ~/.config/quickshell/ii/modules/ii/bar/ClaudeUsagePopup.qml
```

Luego reiniciar Quickshell: `killall qs && qs -c ii &`

No hay entorno de staging. Se prueba directo en prod.
