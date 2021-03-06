# find / wc
CHAOS_TXT_FILE_COUNT = 32771

@exercises << Exercise.new(
    'Find what you search for',
    'Machen Sie sich mit der Funktionsweise von find, wc und Pipes zur Ausgabeumleitung (|) vertraut.',
    %Q{
      Sie wollen sich erstmal einen Überblick über Die wichtigsten Dokumente verschaffen, die alle als .txt-Dateien in `#{PROJEKT_PATH}/chaos` gespeichert sind.

      Finden Sie _alle_ .txt-Dateien im `chaos`-Ordner (und den Unterordnern).
    },
    'Trage hier ein, wieviele .txt-Dateien im Ordner vorhanden sind:',
    'find chaos/ -name "*.txt" | wc',
    -> () { read_console_i == CHAOS_TXT_FILE_COUNT }
)
