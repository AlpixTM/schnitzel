#!/usr/bin/env ruby

# Interaktive Schnitzeljagd, um die Linux-Konsole kennen zu lernen.

# ------------
# Constants
# ------------

# Base path to all our files
BASE_PATH = "#{Dir.home}"

# Our directory (without base path)
PROJEKT_PATH = "linux-kurs"

# Full Path
PATH = "#{BASE_PATH}/#{PROJEKT_PATH}"

# File to log the progress
LOG_FILE = "#{PATH}/.schnitzel.log"

# Text ot ask for <ENTER>
ENTER_TEXT = "Drücken Sie <ENTER>, um die Lösung zu überprüfen:"

# Location of the prepared tar
CHAOS_URL = "https://smits-net.de/files/ei/chaos.tar.xz"

# Some "arbitrary" file names
FILENAMES=[
  'Battlefield',
  'BioShock',
  'Borderlands',
  'Burnout',
  'Castlevania',
  'Crysis',
  'Deponia',
  'Doom',
  'Elite',
  'Fallout',
  'Halo',
  'Hitman',
  'Minecraft',
  'Payday',
  'Prey',
  'Quake',
  'Rayman',
  'Risen',
  'Splatoon',
  'Thief',
  'Uncharted',
  'Witcher',
  'Wolfenstein',
  'Yakuza',
  'Zork',
]

# ------------
# OS dependencies
# ------------

if RUBY_PLATFORM =~ /linux/
  # Linux
  STAT_USER = 'stat -c %U'
  STAT_PERMISSIONS = 'stat -c %a'
  STAT_LINK_COUNT = 'stat -c %h'
elsif RUBY_PLATFORM =~ /darwin/
  # MacOS
  STAT_USER = 'stat -f %Su'
  STAT_PERMISSIONS = 'stat -f %Lp'
  STAT_LINK_COUNT = 'stat -f %l'
else
  # Unknown OS
  puts "Unknown operating system. Exiting..."
  exit 1
end

# ------------
# Classes
# ------------

##
# Class to store the single exercises to be performed
# by the students.
class Exercise
  attr_accessor :title, :purpose, :task, :input_message, :solution, :check, :setup, :teardown

  ##
  # Create a new instance.
  #
  # @param title String the title of the exercise
  # @param purpose String what should the student now beforehand
  # @param task String the actual task to be performed
  # @param input_message String|symbol what to display as input prompt. If set to
  #        symbol :enter the standard Message from ENTER_TEXT ist printed
  # @param solution String the correct command
  # @param check Proc check for the exercise, returns +true+ or +false+
  # @param setup Proc preparation of the exercise. Ignored if nil
  # @param teardown Proc cleanup after the exercise
  def initialize(title, purpose, task, input_message, solution, check, setup = nil, teardown = nil)
    @title = title
    @purpose = purpose
    @task = task
    @input_message = input_message
    @solution = solution
    @check = check
    @setup = setup
    @teardown = teardown
  end

  ##
  # Execute this exercise
  def execute

    @setup.call if @setup
    puts "#{red(@title)}\n\n"
    puts "#{yellow(@purpose)}\n\n"
    puts %Q{#{@task.strip.split("\n").map(&:strip).join("\n")}\n\n}

    begin
      if @input_message == :enter
        print "#{bold(ENTER_TEXT)} "
        $stdin.gets
      else
        print "#{bold(@input_message)} "
      end

      passed = @check.call

      if (!passed)
        puts red("\nLeider falsch. Probieren Sie es noch einmal.\n")
      end
    end while !passed

    puts green("\nKorrekt. Gut gemacht!\n")
  end
end

# ------------
# Helper functions
# ------------

##
# Get an input from stdin
# @return String the data
def input
  $stdin.gets.strip
end

##
# Create a directory (if not already present) and set
# the protections according to the given mask
# @param path String path to the directory
# @param mask Integer umask to be used in creating the direcory
def mkdir(path, mask = 0700)
  Dir.mkdir(path, mask) unless Dir.exists?(path)
end

##
# Fill an directory with files
# @param path String path to the directory
def fill_dir(path)
  FILENAMES.each { |l| File.write("#{path}/#{l}", "Gehen Sie weiter, hier gibt es nichts zu sehen.") }
end

##
# Create the working directory for the tasks
def create_workdir
  mkdir("#{PATH}")
end

##
# Format the text for an ANSI terminal in red
# @param txt String the text to be formatted
# @return String the formatted text
def red(txt)
  "\033[0;31m#{txt}\033[0m"
end

##
# Format the text for an ANSI terminal in green
# @param txt String the text to be formatted
# @return String the formatted text
def green(txt)
  "\033[0;32m#{txt}\033[0m"
end

##
# Format the text for an ANSI terminal in blue
# @param txt String the text to be formatted
# @return String the formatted text
def blue(txt)
  "\033[0;34m#{txt}\033[0m"
end

##
# Format the text for an ANSI terminal in yellow
# @param txt String the text to be formatted
# @return String the formatted text
def yellow(txt)
  "\033[1;33m#{txt}\033[0m"
end

##
# Format the text for an ANSI terminal in grey
# @param txt String the text to be formatted
# @return String the formatted text
def grey(txt)
  "\033[1;30m#{txt}\033[0m"
end

##
# Format the text for an ANSI terminal in bold
# @param txt String the text to be formatted
# @return String the formatted text
def bold(txt)
  "\033[1m#{txt}\033[0m"
end

##
# Provide ANSI escape sequence to clear the screen
# @return String the clearing sequence
def cls
  "\033[2J\033[H"
end

##
# Create a progress bar string
# @param max Integer maximum value
# @param actual Integer actual value
# @param width Integer width of the bar (without the a/m display)
def progress_bar(max, actual, width)
  progress = actual.to_f / max.to_f
  filled = (width * progress).to_i
  empty = (width - filled).to_i

  output = ''
  filled.times { output << "\u2588" }
  empty.times { output << "\u2591" }

  output << " #{actual}/#{max}"

  output
end

##
# Get the last exercise from the log file, if present. Otherwise
# return 0
# @return the last exercise sucessfully performed
def next_exercise
  start = 0
  if File.exists?(LOG_FILE)
    contents = File.readlines(LOG_FILE)
    start = contents.last.split("\t").first.to_i + 1
  end
  start
end

##
# Log the sucess of an exercise
# @param index the index of the exercise performed
def log_success(index, exercise)
  create_workdir
  File.open(LOG_FILE, "a") do |f|
    f.print("#{index}\t#{ENV['USER']}\t'#{exercise.title}'\t#{Time.new}\n")
  end
end

# ------------
# The exercises
# ------------

exercises = []

# man
exercises << Exercise.new(
    'Hilfe',
    'Lernen Sie, sich die Hilfe von Programmen anzeigen zu lassen.',
    %Q{
      Sie möchten mehr über ein Linux-Kommando erfahren. Dies erfolgt bei den meisten Kommandos über den Befehl "man". Bei manchen Kommandos kann man auch als Option "--help" angeben.

      Geben Sie "man ls" ein und finden Sie heraus, mit welcher Option von ls man die Einträge nach dem Datum der letzen Veränderung sortieren kann.
    },
    'Wie lautet das gesuchte Kommando (inklusive ls)?',
    'ls -t',
    -> () { input == 'ls -t' }
)

# vi / nano
exercises << Exercise.new(
  'Erstkontakt',
  'Lernen Sie in Verzeichnisse zu wechseln (cd) und Dateien zu editieren (vi / nano).',
  %Q{
    Sie möchten eine Datei mit Ihre, Lieblingsfilm anlegen - der übrigens "Pulp Fiction" heißt.

    Gehen Sie in das Verzeichnis "#{PROJEKT_PATH}" und lege dort eine Datei mit dem Namen "film.txt" an, in die Sie "Pulp Fiction" schreiben. Verwenden Sie hierzu entweder den Editor vi oder nano.
  },
  :enter,
  'cd ; cd linux-kurs ; echo "Pulp Fiction" > film.txt',
  -> () { f = "#{PATH}/film.txt"; File.exists?(f) && File.read(f).strip == "Pulp Fiction" },
  -> () { create_workdir }
)

# vi / nano
exercises << Exercise.new(
  'Datei editieren',
  'Eine vorhandene Datei mit einem Editor bearbeiten.',
  %Q{
    Sie möchten eine Datei mit Lieblingsfilmen von jemand anderem editieren.

    Gehen Sie in das Verzeichnis "#{PROJEKT_PATH}" und editieren Sie die Datei "prof-filme.txt", die dort liegt. Entfernen Sie den Film "Blade Runner", den Sie (unverständlicherweise) persönlich nicht mögen.
  },
  :enter,
  'vi prof-filme.txt; J DD :w :q',
  -> () { File.read("#{PATH}/prof-filme.txt").strip == "Pulp Fiction\nAlien\nFight Club" },
  -> () { create_workdir; File.write("#{PATH}/prof-filme.txt", "Pulp Fiction\nBlade Runner\nAlien\nFight Club\n") }
)

# less
exercises << Exercise.new(
  'Der Preis eines Schnitzels',
  'Machen Sie sich mit der Funktionsweise von cd, ls, less und more vertraut.',
  %Q{
    Sie führen ein Schnitzelrestaurant und haben leider vergessen, was Sie für Ihre Gerichte verlangen.

    Zum Glück haben Sie die Speisekarte in der Datei "speisekarte.txt" im "#{PROJEKT_PATH}"-Ordner gespeichert.

    Schaue Sie in der Datei nach dem Preis für ein Wiener-Schnitzel.
  },
  'Welchen Preis hat das Wiener Schnitzel?',
  'less speisekarte.txt',
  -> () { input == "23,42" },
  -> () { File.write("#{PATH}/speisekarte.txt", "Wiener Schnitzel 23,42\nJägerschnitzel 28,44\nBauernschnitzel 24,13") }
)

# mkdir / cp
exercises << Exercise.new(
  'Life, Death & Taxes',
  'Machen Sie sich mit der Funktionsweise von mkdir und cp vertraut.',
  %Q{
    Der Steuerberater Ihres Restaurants braucht ein paar Unterlagen von Ihnen.

    Erstelle für ihn einen Ordner "tax-man" im "#{PROJEKT_PATH}"-Verzeichnis.

    Kopieren Sie die Datei "speisekarte.txt" aus dem "#{PROJEKT_PATH}"-Verzeichnis in das "tax-man" Verzeichnis.
   },
   :enter,
   'mkdir tax-man; cp speisekarte.txt tax-man/',
  -> () { File.exists?("#{PATH}/tax-man/speisekarte.txt") && File.read("#{PATH}/speisekarte.txt") == File.read("#{PATH}/tax-man/speisekarte.txt") }
)

# mv
exercises << Exercise.new(
    'Geld stinkt nicht',
    'Machen Sie sich mit der Funktionsweise von mv vertraut.',
    %Q{
      Ihr Steuerberater braucht noch weitere Unterlagen, die alle im Ordner "#{PROJEKT_PATH}/laundry" liegen.

      Bewegen Sie den Ordner "laundry", samt seines Inhaltes, in das "tax-man"-Verzeichnis in "#{PROJEKT_PATH}".
    },
    :enter,
    'mv laundry tax-man',
    -> () do
        ok = true
        ('a'..'z').each { |l| ok = ok && File.exists?("#{PATH}/tax-man/laundry/#{l}") }
        Dir.exists?("#{PATH}/tax-man/laundry") &&
        !Dir.exists?("#{PATH}/laundry") && ok
    end,
    -> () do
      mkdir("#{PATH}/laundry")
      ('a'..'z').each { |l| File.write("#{PATH}/laundry/#{l}", "--egal--") }
    end
)

# rm
exercises << Exercise.new(
    'Unter den Teppich kehren',
    'Machen Sie sich mit der Funktionsweise von rm vertraut.',
    %Q{
      Sie sind sich klar geworden, dass man eine Speisekarte vielleicht doch nicht als .txt-Datei verwaltet und haben Sie bereits in ein passendes Format übertragen.

      Lösche Sie die Datei "speisekarte.txt" aus dem #{PROJEKT_PATH}-Verzeichnis.
    },
    :enter,
    'rm speisekarte.txt',
    -> () { !File.exists?("#{PATH}/speisekarte.txt") }
)

# whoami
exercises << Exercise.new(
    'Wer bin ich?',
    'Mache Sie sich mit der Funktionsweise von whoami vertraut.',
    %Q{
      Finde Sie heraus, als welcher Benutzer Sie im System angemeldet sind.
    },
    'Tragen Sie hier ein, wie Ihr Benutzer heißt:',
    'whoami',
    -> () { input == ENV['USER'] }
)

# ls -axl
exercises << Exercise.new(
    'Wem gehört denn das?',
    'Vertiefen Sie Ihr Wissen zu ls.',
    %Q{
      Sie verwalten Dateien zu zwielichtigen Geschäften im Ordner "shady-business" im "#{PROJEKT_PATH}"-Verzeichnis.

      Finden Sie heraus, welcher Benutzer der Besitzer des Ordners "shady-business" ist.
    },
    'Trage Sie hier den Namen des Besitzers ein:',
    'ls -axl',
    -> () { input == ENV['USER'] },
    -> () { mkdir("#{PATH}/shady-business", 0700) }
)

# sudo / chown
exercises << Exercise.new(
    'What a Superuser can do',
    'Machen Sie sich mit der Funktionsweise von sudo und chown vertraut.',
    %Q{
      Nutzen Sie die Macht eines Superusers und setzen den Besitzer des Ordners "shady-business" auf "nobody", damit man Ihnen später nichts nachsagen kann.
    },
    :enter,
    'sudo chown nobody shady-business',
    -> () { `#{STAT_USER} #{PATH}/shady-business`.strip == 'nobody' },
    -> () { mkdir("#{PATH}/shady-business"); fill_dir("#{PATH}/shady-business") }
)

# mv
exercises << Exercise.new(
    'Move on...there is nothing to see here',
    'Frischen Sie Ihr Wissen zu mv ein wenig auf.',
    %Q{
      Das Finanzamt hat Unstimmigkeiten in Ihrer Steuererklärung festgestellt und Sie wollen Ihre Spuren zu den zwielichtigen Geschäften verwischen.

      Änderen Sie den Namen des Ordners "shady-business" in "nothing-to-see-here" um.
    },
    :enter,
    'sudo mv shady-business nothing-to-see-here',
    -> () { !File.exists?("#{PATH}/shady-business") && File.exists?("#{PATH}/nothing-to-see-here") }
)

# chmod
exercises << Exercise.new(
    'Read, Write and Execute',
    'Machen Sie sich mit der Funktionsweise von chmod vertraut.',
    %Q{
      Ihre Geschäftspartner brauchen Zugang zu den zwielichtigen Dokumenten.

      Änderen Sie die Zugriffsrechte des "nothing-to-see-here"-Ordners so um, dass jeder Benutzer darin Lesen, Schreiben und Ausführen kann.
    },
    :enter,
    'sudo chmod og+rwx nothing-to-see-here',
    -> () { p = `#{STAT_PERMISSIONS} #{PATH}/nothing-to-see-here`.strip; p == '777' || p == '707' }
)

# rm -rf
exercises << Exercise.new(
    'Ist das Kunst, oder kann das weg?',
    'Frischen Sie Ihr Wissen zu rm ein wenig auf.',
    %Q{
      Die Steuerfahndung ist Ihnen auf der Spur und Ihnen wird die Sache zu heiß. Sie entscheiden sich, alle Dokumente, die Sie mit zwielichtigen Geschäften in Verbindung bringen könnten zu löschen.

      Löschen Sie den Ordner "nothing-to-see-here", zusammen mit seinem Inhalt.
    },
    :enter,
    'rm -rf nothing-to-see-here',
    -> () { !File.exists?("#{PATH}/nothing-to-see-here") }
)

# wget
exercises << Exercise.new(
    'Ein neues Kapitel',
    'Mache Sie sich mit der Funktionsweise von wget vertraut.',
    %Q{
      Sie haben sich auf eine karibische Insel abgesetzt und wollen dort mit einem Schnitzelrestaurant wieder neu anfangen, diesmal aber ohne zwielichtige Geschäftspraktiken. Noch in Deutschland haben Sie wichtige Dokumente archiviert und online gestellt.

      Laden Sie die Ressource unter: #{CHAOS_URL}

      ...in das "#{PROJEKT_PATH}"-Verzeichnis herunter.
    },
    :enter,
    "wget #{CHAOS_URL}",
    -> () { File.exists?("#{PATH}/chaos.tar.xz") && File.size("#{PATH}/chaos.tar.xz") == 5454500 }
)

# tar
exercises << Exercise.new(
    'Archive',
    'Machen Sie sich mit der Funktionsweise von tar vertraut.',
    %Q{
      Die Dokumente wurden in einem Archiv gespeichert, um sie kompakt und gebündelt zu verwalten.

      Entpacken Sie das heruntergeladene Archiv in den Ordner "#{PROJEKT_PATH}".
    },
    :enter,
    'tar -xJf chaos.tar.xz',
    -> () { Dir.exists?("#{PATH}/chaos") && Dir["#{PATH}/chaos/**/*"].count == 65538 }
)

# find / wc
exercises << Exercise.new(
    'Find what you search for',
    'Mache Sie sich mit der Funktionsweise von find vertraut.',
    %Q{
      Sie wollen sich erstmal einen Überblick über Die wichtigsten Dokumente verschaffen, die alle als .txt-Dateien in "#{PROJEKT_PATH}/chaos" gespeichert sind.

      Finden Sie alle .txt-Dateien im "chaos"-Ordner (und den Unterordnern).
    },
    'Trage hier ein, wieviele .txt-Dateien im Ordner vorhanden sind:',
    'find chaos/ -name "*.txt" | wc',
    -> () { input.to_i == 32771 }
)

=begin
exercises << Exercise.new(
    'Build a Pipeline',
    'Mache Sie sich mit der Funktionsweise von find, wc und der Pipe ("|") vertraut.',
    %Q{
      Sie wollen sich erstmal einen Überblick über Die wichtigsten Dokumente verschaffen, die alle als .txt-Dateien in "#{PROJEKT_PATH}/chaos" gespeichert sind.

      Erstellen Sie eine Pipeline, die alle .txt-Dateien im "chaos"-Ordner, deren Inhalt ausgibt und anschließend die Zeilen zählt.
    },
    'Tragen Sie hier ein, wieviele Zeilen die .txt-Dateien in Summe haben:',
    '',
    -> () { input.to_i == 42 }
)
=end

# grep
exercises << Exercise.new(
    'Find the key',
    'Machen Sie sich mit der Funktionsweise von grep vertraut.',
    %Q{
      Sie suchen nach einem wichtigen Passwort, wissen aber nicht mehr wo es steht.

      Sie wissen nur, dass es irgendwo in einer Datei im "chaos"-Ordner gespeichert ist und sowohl mit einem "#" anfängt, als auch aufhört.

      Navigieren Sie in den Ordner "#{PROJEKT_PATH}/chaos".

      Nutzen Sie grep, um das Passwort zu finden. (Tipp: der richige reguläre Ausdruck ist "#.*#").
    },
    'Wie lautet das magische Passwort (ohne die #)?',
    'grep -roh "#.*#"',
    -> () { input == "parmigiana4life" }
)

# diff
exercises << Exercise.new(
    'Find the difference',
    'Machen Sie sich mit der Funktionsweise von diff vertraut.',
    %Q{
      Sie suchen nach einem kleinen Unterschied zwischen zwei Dateien.

      Verwenden Sie diff, um den Unterschied zwischen den beiden Dateien "kafka1.txt" und "kafka2.txt" im "chaos"-Ordner zu finden.
    },
    'Wie lautet der Unterschied?',
    'diff kafka1.txt kafka2.txt',
    -> () { input == "Informatik ist cool" }
)

# sort / uniq / > / |
exercises << Exercise.new(
    'Sortieren und ordnen',
    'Machen Sie sich mit der Funktionsweise von sort, uniq und der Ausgabeumleitung (<,>,|) vertraut.',
    %Q{
      Im Ordner "chaos" befindet sich eine Wortliste in der Datei "wortliste.txt", die jedoch beim Transport heftig durcheinander geraten ist. Außerdem sind noch einige Worte mehrfach vorhanden.

      Verwenden Sie sort und uniq, um die Liste zu sortieren und Doubletten zu entfernen. Speichern Sie das Ergebnis in der Datei "wortliste_sortiert.txt" im Ordner "#{PROJEKT_PATH}".
    },
    :enter,
    'cd chaos; sort wortliste.txt | uniq > ../wortliste_sortiert.txt',
    -> () { f = "#{PATH}/wortliste_sortiert.txt"; File.exists?(f) && (File.readlines(f)[142].strip == 'ausbauchen' || File.readlines(f)[142].strip == 'Behelfsverkaufsstelle') }
)

# grep / sed / | / >
exercises << Exercise.new(
    'Monnheim',
    'Machen Sie sich mit der Funktionsweise von grep, sed und der Ausgabeumleitung (<,>,|) vertraut.',
    %Q{
      Sie wollen aus der sortierten Wortliste einige Wörter mit "grep" heraussuchen und diese dann mit "sed" verändern.

      Finden Sie alle Wörter in der Liste "wortliste_sortiert.txt", in denen die Buchstabenfolge "heim" vorkommt. Ersetzen Sie diese Buchstaben durch "mannheim" und schreiben Sie das Ergebnis in eine neue Datei "monnheim.txt" im Ordner "#{PROJEKT_PATH}".
    },
    :enter,
    'grep heim wortliste_sortiert.txt | sed -e "s/heim/mannheim/g" > monnheim.txt',
    -> () { f = "#{PATH}/monnheim.txt"; File.exists?(f) && File.readlines(f).map(&:chomp) == [ 'Billigmannheim', 'Blindenmannheim', 'Gemannheimkonto', 'Saisonmannheimspiel', 'Sportlermannheim' ] }
)

# ln -s
exercises << Exercise.new(
    'Was heißt hier Softie?',
    'Machen Sie sich mit der Funktionsweise von Hard- und Softlinks und dem Kommando "ln" vertraut.',
    %Q{
      Im Ordner "#{PROJEKT_PATH}" finden Sie eine Datei namens "highlander.txt". Erstellen Sie einen Softlink (symbolischer Link) namens "macleod.txt" auf diese Datei.
    },
    :enter,
    'ln -s highlander.txt macleod.txt',
    -> () { f = "#{PATH}/macleod.txt"; File.exists?(f) && File.symlink?(f) },
    -> () { f = "#{PATH}/highlander.txt"; File.write(f, "Es kann nur einen geben!\n\n") unless File.exists?(f) }
)

# ln
exercises << Exercise.new(
    'Nur die Harten kommen in den Garten',
    'Machen Sie sich mit der Funktionsweise von Hard- und Softlinks und dem Kommando "ln" vertraut.',
    %Q{
      Im Ordner "#{PROJEKT_PATH}" finden Sie eine Datei namens "highlander.txt". Erstellen Sie einen Hardlink namens "fasil.txt" auf diese Datei. Öffnen Sie nun "fasil.txt" in einem Texteditor und ändern Sie den Inhalt zu "Es kann nur zwei geben!" und speichern Sie den Inhalt. Sehen Sie sich danach die Datei "highlander.txt" an.
    },
    :enter,
    'ln highlander.txt fasil.txt',
    -> () { f = "#{PATH}/fasil.txt"; File.exists?(f) && File.read(f).strip == "Es kann nur zwei geben!" && `#{STAT_LINK_COUNT} #{f}`.strip == "2" },
    -> () { f = "#{PATH}/highlander.txt"; File.write(f, "Es kann nur einen geben!\n\n") unless File.exists?(f) }
)

# ps / kill
exercises << Exercise.new(
    'Vertrauen ist nichts, Kontrolle ist alles',
    'Machen Sie sich mit der Funktionsweise "ps" und "kill" vertraut.',
    %Q{
      Auf Ihrem System läut ein Prozess mit dem Namen "sleep". Finden Sie ihn und beenden Sie den Prozess. Möglicherweise laufen auch mehrere Prozesse, dann beenden Sie alle mit dem Namen "sleep".
    },
    :enter,
    'ps aux | grep sleep ; kill ...',
    -> () { `ps aux | grep sleep | grep -v "grep"`.strip == "" },
    -> () { p = fork { exec "sleep 100000" }; Process.detach(p) }
)

=begin
exercises << Exercise.new(
    'Get the Parrot',
    'Mache dich mit der Funktionsweise von gpg vertraut.',
    %Q{
      Du hast eine verschlüsselte Datei, die mit dem eben gefundenen Passwort verschlüsselt wurde. Um die Datei zu lesen, musst du sie vorher entschlüsseln.

      Navigiere in den Ordner #{PROJEKT_PATH}/chaos und betrachte die Datei "papagei.txt.gpg" mit Hilfe von nano.

      Entschlüssele die Datei mit dem Befehl [gpg -d papagei.txt.gpg] (ohne die Klammern).

      Der Inhalt der verschlüsselten Datei wird auf dem Bildschirm ausgegeben.
    },
    '',
    'Trage hier den Inhalt der verschlüsselten Datei ein:',
    -> () { $stdin.gets.chomp == '42' }
)
=end

start = next_exercise

# Override current progress from
# the command line
if ARGV[0]
  start = ARGV[0].to_i
end

# Execute the exercises
exercises.each_with_index do |exercise, index|

  # Skip already finished exercises
  next if index < start

  # Execute the exercise and log success
  puts "#{cls}"
  print progress_bar(exercises.length, index, 70)
  print "\n\n"
  exercise.execute
  log_success(index, exercise)

  Kernel.sleep(2)
end

puts "#{cls}"
print progress_bar(exercises.length, exercises.length, 70)
puts green("\n\nAlle Augaben gelöst. Herzlichen Glückwunsch!\n")
