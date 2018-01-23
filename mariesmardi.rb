require "google_drive"
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'gmail'

# Creates a session. This will prompt the credential via command line for the
# first time and save it to config.json file for later usages.
# See this document to learn how to create config.json:
# https://github.com/gimite/google-drive-ruby/blob/master/doc/authorization.md
session = GoogleDrive::Session.from_config("config.json")

# First worksheet of
# https://docs.google.com/spreadsheet/ccc?key=pz7XtlQC-PYx-jrVMJErTcg
# Or https://docs.google.com/a/someone.com/spreadsheets/d/pz7XtlQC-PYx-jrVMJErTcg/edit?usp=drive_web
ws = session.spreadsheet_by_key("*********************").worksheets[0]

# require 'pry'

# page = Nokogiri::HTML(open("http://annuaire-des-mairies.com/95/vaureal.html"))   
# puts page.class 
# => Nokogiri::HTML::Document

# méthode pour récupérer l'adresse email d'une page web de mairie
def gets_the_email_of_townhall_from_its_webpage(url)
	page = Nokogiri::HTML(open(url))
	emails = page.css("tr td.style27 p.Style22 font") # array emails regroupant les éléments dont le chemin a été précisé
	emails.each do |i| # itération sur l'array pour obtenir l'élément i
		if i.text.include?"@"
			return i.text # on affiche le texte de l'élément i
		end
	end
end

# méthode pour récupérer les url et ranger dans un Hash les paires Ville / emails
def get_all_the_urls_of_valdoise_townhalls
		town_hash = Hash.new('0') # création du Hash town_hash
		page = Nokogiri::HTML(open("http://annuaire-des-mairies.com/val-d-oise.html"))
		urls = page.css("a.lientxt") # on définit une variable urls qui renvoie à un array des a de classe lientxt
		urls.each do |url| # itération sur l'array pour obtenir l'élément url
			clean_url = "http://annuaire-des-mairies.com"+url['href'][1..url['href'].length] # clean url est un string concaténé de http://...et de l'attribut href de l'élément url sans son premier caractère
			town_hash[url.text] = gets_the_email_of_townhall_from_its_webpage(clean_url) # classement dans le hash
		end
		return town_hash
end

town_hash = Hash.new('0')
town_hash = get_all_the_urls_of_valdoise_townhalls


puts town_hash
# Changes content of cells.
# Changes are not sent to the server until you call ws.save().
town_hash.each_with_index do  |town_hash, i| 
	ws[i+1,2] = town_hash [1]
	ws[i+1,1] = town_hash [0] 
	ws.save
end

#récupérer les données des spreadsheets 
def data_spreadsheet
	#appel des tokens avec le fichier j.Son
session = GoogleDrive::Session.from_config("config.json")
#appel de la worksheet de sa feuille [0] dans la variable ws
ws = session.spreadsheet_by_key("***********").worksheets[0]
#formation d'une boucle avec condition while, qui continuera jusqu'à ce que ce que la colonne 2 soit vide et fausse
	i = 1
	while ws[i,2].empty? == false
	# compteur pour aller à la boucle suivante et exécuter la boucle un certain nombre de fois
	i += 1 
# appel de la méthode pour envoyer le mail avec deux arguments ( les 2 colonnes de la spreadsheet) qui sont l adresse email et le nom de la mairie
	send_email(ws[i,2], ws[i,1])
	end
end

#méthode d'envoi d 'email avec le nom de la mairie en arguments
def send_email(destinataire, nom)
	#connection à gmail et je cache mon mot de passe
	gmail = Gmail.connect("chloe.jungkuss@gmail.com","*****")
	#fonction envoyer un mail chaque valeur de la colonne 2 (ws[i,2]dans la spreadsheet ira en destinataire)
	gmail.deliver do to destinataire
		subject "Bonjour mairie de #{nom}!"
		#body 
		part do
		# appel du contenu du mail via la méthode "content_email"
		content_type "text"
		# encodage du message
        body content_email(nom) # appel du contenu du mail via la méthode "content_email
			    			
			    end
			    gmail.logout # du coup je me déconnecte
			end

			# contenu du mail à envoyer à chaque mairie. L'argument "nom" est présent pour l'intégrer facilement dans le message
			def content_email(nom)
				"Bonjour,

Je m'appelle Chloé, je suis élève à une formation de code gratuite, ouverte à tous, 
sans restriction géographique, ni restriction de niveau. 
La formation s'appelle The Hacking Project (http://thehackingproject.org/). 
Nous apprenons l'informatique via la méthode du peer-learning : 
nous faisons des projets concrets qui nous sont assignés tous les jours, sur lesquel nous planchons en petites équipes autonomes.
 Le projet du jour est d'envoyer des emails à nos élus locaux pour qu'ils nous aident à faire de The Hacking Project 
 un nouveau format d'éducation gratuite.

Nous vous contactons pour vous parler du projet, et vous dire que vous pouvez ouvrir une cellule à {townhall_name}, 
où vous pouvez former gratuitement 6 personnes (ou plus), qu'elles soient débutantes, ou confirmées. 
Le modèle d'éducation de The Hacking Project n'a pas de limite en terme de nombre de moussaillons 
(c'est comme cela que l'on appelle les élèves), donc nous serions ravis de travailler avec {townhall_name} !

Charles, co-fondateur de The Hacking Project pourra répondre à toutes vos questions : 06.95.46.60.80"
			 
			 end

			# youpi, on appelle la première méthode ;
			
			data_spreadsheet
end
