1. Tibber Access Token erhalten

    Rufe das Tibber Developer Portal auf und klicke oben rechts auf "Sign in".
    https://developer.tibber.com/
    Melde dich mit deinen gewohnten Tibber-Zugangsdaten an.
    Gehe im Menü auf den Reiter "Access Token" und klicke auf "Create Token".
    https://developer.tibber.com/settings/access-token
    Kopiere den generierten Token. Dies ist dein <API_TOKEN>.

3. Home ID auslesen

    Navigiere im Developer Portal zum API Explorer.
    Klicke auf "Load personal token", damit dein <API_TOKEN> automatisch geladen wird.
    Nutze die folgende Abfrage im linken Fenster und drücke den Play-Button nachdem du den folgenden Code eingeben hast:
   
   {
  viewer {
    homes {
      id
      address {
        address1
      }
    }
  }
}

5. Im rechten Ergebnisfenster findest du unter id deine <HOME_ID> (eine lange Zeichenfolge aus Buchstaben und Zahlen).

Hinweis: Bewahre sowohl den <API_TOKEN> als auch die <HOME_ID> sicher auf, da diese wie Passwörter für deine Verbrauchsdaten fungieren.
   
