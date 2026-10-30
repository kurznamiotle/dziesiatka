-- 100 kolejnych ciekawostek do testów, po 20 w każdej kategorii.
-- Uruchom raz w SQL Editor. Ponowne uruchomienie nie tworzy duplikatów.

insert into public.facts
  (id, title, category, short_text, long_text, source_label, source_url, quiz, status)
values
  ('fact-051', 'Burza większa od Ziemi', 'Kosmos', 'Wielka Czerwona Plama na Jowiszu to burza szersza od całej Ziemi.', 'Ten ogromny wir szaleje w atmosferze Jowisza od co najmniej 150 lat, a wiatry na jego skraju przekraczają 400 km/h.

Obserwacje pokazują, że plama powoli się kurczy. Dawniej mieściłaby trzy Ziemie, dziś jej szerokość odpowiada mniej więcej średnicy jednej.', 'NASA', 'https://science.nasa.gov/jupiter/', '{"question": "Czym jest Wielka Czerwona Plama?", "options": ["Kraterem po uderzeniu", "Morzem lawy", "Ogromną burzą"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-052', 'Rok w 88 dni', 'Kosmos', 'Rok na Merkurym trwa zaledwie 88 ziemskich dni.', 'Merkury krąży najbliżej Słońca, dlatego okrąża je najszybciej ze wszystkich planet.

Obraca się za to bardzo wolno: od wschodu do wschodu Słońca mija tam około 176 ziemskich dni, czyli dwa tamtejsze lata.', 'NASA', 'https://science.nasa.gov/mercury/', '{"question": "Ile trwa rok na Merkurym?", "options": ["Około 12 ziemskich lat", "Około 365 ziemskich dni", "Około 88 ziemskich dni"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-053', 'Księżyc ucieka', 'Kosmos', 'Księżyc oddala się od Ziemi o około 3,8 cm rocznie.', 'Odległość mierzy się laserem, odbijając światło od lusterek pozostawionych na Księżycu podczas misji Apollo.

Za oddalanie odpowiadają pływy: Ziemia traci przez nie energię obrotu, a Księżyc ją przejmuje. Doby stają się przez to bardzo powoli dłuższe.', 'NASA', 'https://science.nasa.gov/moon/', '{"question": "Jak mierzy się odległość do Księżyca?", "options": ["Długością cienia Ziemi", "Sondą z taśmą mierniczą", "Laserem odbijanym od lusterek"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-054', 'Zawsze ta sama twarz', 'Kosmos', 'Z Ziemi widzimy zawsze tę samą stronę Księżyca.', 'Księżyc obraca się wokół własnej osi dokładnie tak długo, jak okrąża Ziemię. Zjawisko to nazywa się obrotem synchronicznym.

Drugą stronę ludzie zobaczyli dopiero w 1959 roku, na zdjęciach radzieckiej sondy Łuna 3. Nie jest ona ciemna: Słońce oświetla ją tak samo często.', 'NASA', 'https://science.nasa.gov/moon/', '{"question": "Kiedy ludzie po raz pierwszy zobaczyli drugą stronę Księżyca?", "options": ["W 1999 roku", "W 1959 roku", "W 1609 roku"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-055', 'Planeta na boku', 'Kosmos', 'Uran obraca się niemal leżąc na boku.', 'Oś obrotu Urana jest pochylona o około 98 stopni, więc planeta toczy się po orbicie jak kula.

Najczęściej tłumaczy się to dawnym zderzeniem z dużym ciałem. Przez takie ustawienie każdy biegun ma tam kolejno ponad 40 lat dnia i 40 lat nocy.', 'NASA', 'https://science.nasa.gov/uranus/', '{"question": "O ile stopni pochylona jest oś Urana?", "options": ["O około 23", "O około 98", "O około 5"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-056', 'Pierwszy rok Neptuna', 'Kosmos', 'Neptun ukończył pierwsze okrążenie Słońca od odkrycia dopiero w 2011 roku.', 'Planetę odkryto w 1846 roku, a jeden jej rok trwa około 165 ziemskich lat.

Odkrycie było triumfem matematyki: położenie Neptuna wyliczono z zaburzeń ruchu Urana, zanim ktokolwiek zobaczył go przez teleskop.', 'NASA', 'https://science.nasa.gov/neptune/', '{"question": "Ile ziemskich lat trwa rok na Neptunie?", "options": ["Około 16", "Około 165", "Około 1650"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-057', 'Światło sprzed milionów lat', 'Kosmos', 'Galaktykę Andromedy widać gołym okiem, choć jej światło leci do nas 2,5 mln lat.', 'Andromeda to najdalszy obiekt, jaki większość ludzi może dostrzec bez przyrządów. Pod ciemnym niebem wygląda jak mała, rozmyta plamka.

Oglądamy ją taką, jaka była, gdy na Ziemi żyli dalecy przodkowie człowieka.', 'NASA Science, „Andromeda Galaxy”', null, '{"question": "Ile w przybliżeniu leci do nas światło z Andromedy?", "options": ["2,5 miliona lat", "25 lat", "2,5 tysiąca lat"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-058', 'Najbliższa sąsiadka', 'Kosmos', 'Najbliższa gwiazda poza Słońcem jest oddalona o ponad 4 lata świetlne.', 'Proxima Centauri leży około 4,2 roku świetlnego od nas. Sonda Voyager 1 potrzebowałaby na taką podróż ponad 70 tysięcy lat.

Gwiazda jest czerwonym karłem, zbyt słabym, by zobaczyć ją gołym okiem.', 'Encyclopaedia Britannica, hasło „Proxima Centauri”', null, '{"question": "Jak nazywa się najbliższa gwiazda poza Słońcem?", "options": ["Proxima Centauri", "Syriusz", "Gwiazda Polarna"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-059', 'Jeziora metanu', 'Kosmos', 'Na Tytanie, księżycu Saturna, są jeziora, ale płynie w nich metan i etan.', 'Tytan to jedyny poza Ziemią znany świat ze stabilnymi zbiornikami cieczy na powierzchni. Przy temperaturze około minus 180 stopni Celsjusza woda jest tam twarda jak skała.

W 2005 roku wylądował na nim próbnik Huygens, co pozostaje najdalszym lądowaniem w historii.', 'NASA', 'https://science.nasa.gov/saturn/moons/titan/', '{"question": "Co wypełnia jeziora na Tytanie?", "options": ["Metan i etan", "Woda", "Płynne żelazo"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-060', 'Ocean pod lodem', 'Kosmos', 'Pod lodową skorupą księżyca Europa kryje się słony ocean.', 'Dane z sond wskazują, że pod lodem Europy, księżyca Jowisza, znajduje się globalny ocean. Może mieścić nawet dwa razy więcej wody niż wszystkie oceany Ziemi.

Dlatego Europa należy do najciekawszych miejsc w poszukiwaniu życia poza Ziemią.', 'NASA', 'https://science.nasa.gov/jupiter/jupiter-moons/europa/', '{"question": "Wokół jakiej planety krąży Europa?", "options": ["Wokół Jowisza", "Wokół Marsa", "Wokół Neptuna"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-061', 'Cienkie pierścienie', 'Kosmos', 'Pierścienie Saturna mają setki tysięcy kilometrów szerokości i są zaskakująco cienkie.', 'Główne pierścienie rozciągają się na około 280 tysięcy kilometrów, ale ich typowa grubość to zaledwie około 10 metrów.

Składają się z niezliczonych kawałków lodu i skał, od ziaren po bryły wielkości domu.', 'NASA', 'https://science.nasa.gov/saturn/', '{"question": "Z czego składają się pierścienie Saturna?", "options": ["Z gazu i ognia", "Z czystego żelaza", "Z lodu i skał"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-062', '108 minut Gagarina', 'Kosmos', 'Pierwszy lot człowieka w kosmos trwał tylko 108 minut.', '12 kwietnia 1961 roku Jurij Gagarin okrążył Ziemię raz na pokładzie statku Wostok 1.

Kapsuła nie lądowała z pilotem w środku: Gagarin katapultował się na wysokości kilku kilometrów i opadł na własnym spadochronie.', 'Encyclopaedia Britannica, hasło „Yuri Gagarin”', null, '{"question": "Ile trwał lot Gagarina?", "options": ["108 minut", "8 dni", "18 godzin"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-063', 'Łajka na orbicie', 'Kosmos', 'Pierwszym zwierzęciem na orbicie Ziemi była suczka Łajka.', 'Łajka, bezpańska suczka z Moskwy, poleciała w listopadzie 1957 roku na pokładzie Sputnika 2.

Misja nie przewidywała powrotu na Ziemię. Zwierzę zginęło w ciągu kilku godzin od startu, prawdopodobnie z powodu przegrzania.', 'Encyclopaedia Britannica, hasło „Laika”', null, '{"question": "Na pokładzie jakiego statku poleciała Łajka?", "options": ["Sputnika 2", "Wostoka 1", "Apollo 1"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-064', 'Złota płyta', 'Kosmos', 'Sondy Voyager niosą złotą płytę z dźwiękami i muzyką z Ziemi.', 'Płytę przygotował zespół pod kierunkiem Carla Sagana. Zawiera powitania w dziesiątkach języków, odgłosy natury, zdjęcia i muzykę, od Bacha po Chucka Berry’ego.

Na okładce wyryto instrukcję odtwarzania na wypadek, gdyby ktoś kiedyś ją znalazł.', 'NASA', 'https://science.nasa.gov/mission/voyager/', '{"question": "Kto kierował przygotowaniem złotej płyty?", "options": ["Albert Einstein", "Carl Sagan", "Neil Armstrong"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-065', 'Następna wizyta w 2061', 'Kosmos', 'Kometa Halleya wraca w pobliże Ziemi co około 76 lat.', 'Edmond Halley jako pierwszy obliczył, że komety obserwowane w 1531, 1607 i 1682 roku to jeden i ten sam obiekt, i przewidział jej powrót.

Ostatnio była widoczna w 1986 roku, a następny raz pojawi się w 2061 roku.', 'NASA', 'https://science.nasa.gov/solar-system/comets/1p-halley/', '{"question": "Kiedy kometa Halleya wróci w pobliże Ziemi?", "options": ["W 2031 roku", "W 2061 roku", "W 2161 roku"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-066', 'Prawie cała masa', 'Kosmos', 'Słońce stanowi około 99,8% masy całego Układu Słonecznego.', 'Wszystkie planety, księżyce, komety i planetoidy razem to tylko ułamek procenta. Większość tej reszty przypada na Jowisza.

Taka przewaga sprawia, że grawitacja Słońca utrzymuje na orbitach obiekty odległe o miliardy kilometrów.', 'NASA', 'https://science.nasa.gov/sun/', '{"question": "Jaką część masy Układu Słonecznego stanowi Słońce?", "options": ["Około 50%", "Około 75%", "Około 99,8%"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-067', 'Gorętsza niż Merkury', 'Kosmos', 'Najgorętszą planetą jest Wenus, a nie leżący bliżej Słońca Merkury.', 'Średnia temperatura na powierzchni Wenus to około 465 stopni Celsjusza, czyli tyle, że stopiłby się ołów.

Gęsta atmosfera z dwutlenku węgla działa jak koc i zatrzymuje ciepło. Merkury prawie nie ma atmosfery, więc nocą gwałtownie się wychładza.', 'NASA', 'https://science.nasa.gov/venus/', '{"question": "Co sprawia, że Wenus jest tak gorąca?", "options": ["Bliskość Słońca", "Czynne wulkany na całej powierzchni", "Gęsta atmosfera zatrzymująca ciepło"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-068', 'Niebieskie zachody', 'Kosmos', 'Na Marsie zachody Słońca mają niebieski odcień.', 'Łazik Curiosity sfotografował je kamerami na powierzchni planety. W ciągu dnia niebo Marsa jest rdzawe, ale wokół zachodzącego Słońca robi się chłodnoniebieskie.

Odpowiada za to bardzo drobny pył, który przepuszcza niebieskie światło bliżej kierunku jego biegu.', 'NASA', 'https://science.nasa.gov/mars/', '{"question": "Jaki kolor mają zachody Słońca na Marsie?", "options": ["Fioletowy", "Niebieski", "Zielony"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-069', 'Wyżsi w kosmosie', 'Kosmos', 'W kosmosie astronauci stają się nawet o 3% wyżsi.', 'Bez grawitacji kręgosłup nie jest ściskany i delikatnie się wydłuża. Astronauta może urosnąć o kilka centymetrów.

Po powrocie na Ziemię wzrost wraca do normy. Rozciąganie bywa przy tym przyczyną bólu pleców w trakcie misji.', 'NASA, „Astronauts Answer Student Questions”', null, '{"question": "Dlaczego astronauci stają się wyżsi?", "options": ["Kości stają się grubsze", "Mięśnie nóg szybciej rosną", "Kręgosłup nie jest ściskany przez grawitację"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-070', 'Księżyc większy od planety', 'Kosmos', 'Ganimedes, księżyc Jowisza, jest większy od Merkurego.', 'To największy księżyc Układu Słonecznego, o średnicy około 5300 km. Merkury ma niecałe 4900 km.

Ganimedes jest też jedynym znanym księżycem z własnym polem magnetycznym.', 'NASA', 'https://science.nasa.gov/jupiter/jupiter-moons/ganymede/', '{"question": "Od jakiej planety Ganimedes jest większy?", "options": ["Od Marsa", "Od Merkurego", "Od Ziemi"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-071', 'Najgęstsze futro', 'Zwierzęta', 'Wydry morskie mają najgęstsze futro w świecie zwierząt.', 'Na centymetrze kwadratowym ich skóry może rosnąć ponad 100 tysięcy włosów.

W przeciwieństwie do fok i wielorybów wydry nie mają grubej warstwy tłuszczu. Od lodowatej wody chroni je powietrze uwięzione w futrze, dlatego muszą je stale czyścić.', 'Encyclopaedia Britannica, hasło „Sea otter”', null, '{"question": "Co chroni wydry morskie przed zimnem?", "options": ["Powietrze uwięzione w futrze", "Ciepła krew jak u ryb", "Gruba warstwa tłuszczu"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-072', 'Taniec pszczół', 'Zwierzęta', 'Pszczoły przekazują sobie drogę do kwiatów za pomocą tańca.', 'Pszczoła wykonuje na plastrze taniec w kształcie ósemki. Kąt ruchu wskazuje kierunek względem Słońca, a czas trwania mówi o odległości.

Karl von Frisch, który rozszyfrował ten język, otrzymał w 1973 roku Nagrodę Nobla.', 'Nobel Prize, „Karl von Frisch – Facts”', null, '{"question": "Kto rozszyfrował taniec pszczół?", "options": ["Karl von Frisch", "Karol Darwin", "Iwan Pawłow"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-073', 'Dwa lata ciąży', 'Zwierzęta', 'Ciąża słonia afrykańskiego trwa około 22 miesięcy.', 'To najdłuższa ciąża wśród ssaków lądowych. Słoniątko rodzi się ważąc około 100 kilogramów i po kilku godzinach potrafi już stać.

Długi czas rozwoju sprzyja dużemu i złożonemu mózgowi, który jest potrzebny zwierzętom żyjącym w rozbudowanych stadach.', 'Encyclopaedia Britannica, hasło „Elephant”', null, '{"question": "Ile trwa ciąża słonia afrykańskiego?", "options": ["Około 22 miesięcy", "Około 9 miesięcy", "Około 4 lat"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-074', 'Żaba, która zamarza', 'Zwierzęta', 'Amerykańska żaba leśna potrafi przetrwać zimę częściowo zamarznięta.', 'Zimą w jej ciele może zamarznąć znaczna część wody, a serce przestaje bić. Glukoza i inne związki chronią przy tym komórki przed zniszczeniem.

Gdy nadchodzi odwilż, żaba rozmarza i wraca do życia, jakby nic się nie stało.', 'Encyclopaedia Britannica, hasło „Wood frog”', null, '{"question": "Co dzieje się z sercem zamarzniętej żaby leśnej?", "options": ["Przestaje bić", "Znika", "Bije szybciej"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-075', 'Głowa na 270 stopni', 'Zwierzęta', 'Sowy potrafią obrócić głowę nawet o 270 stopni.', 'Oczy sów są osadzone w czaszce i prawie się nie poruszają, więc ptaki muszą obracać całą głową.

Umożliwia im to aż 14 kręgów szyjnych, dwa razy więcej niż u człowieka, oraz specjalna budowa naczyń krwionośnych, która chroni dopływ krwi do mózgu.', 'Encyclopaedia Britannica, hasło „Owl”', null, '{"question": "Ile kręgów szyjnych ma sowa?", "options": ["3", "7", "14"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-076', 'Kolory z kryształów', 'Zwierzęta', 'Kameleony zmieniają kolor, przesuwając maleńkie kryształki w skórze.', 'W komórkach skóry znajdują się nanokryształy odbijające światło. Gdy kameleon napina lub rozluźnia skórę, zmienia się odległość między nimi, a z nią odbijany kolor.

Zmiana barwy służy głównie komunikacji i regulacji temperatury, a nie kamuflażowi.', 'Teyssier i in., „Photonic crystals cause active colour change in chameleons”, Nature Communications, 2015', null, '{"question": "Do czego kameleony używają zmiany koloru przede wszystkim?", "options": ["Do komunikacji i regulacji temperatury", "Do łapania owadów", "Do odstraszania deszczu"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-077', 'Największe skrzydła', 'Zwierzęta', 'Albatros wędrowny ma największą rozpiętość skrzydeł wśród żyjących ptaków.', 'Skrzydła tego ptaka mogą mierzyć ponad 3 metry. Dzięki nim potrafi szybować godzinami, prawie nimi nie machając.

Albatrosy spędzają na morzu lata i wracają na ląd głównie po to, by się rozmnażać.', 'Encyclopaedia Britannica, hasło „Wandering albatross”', null, '{"question": "Ile może mierzyć rozpiętość skrzydeł albatrosa wędrownego?", "options": ["Około 1 metra", "Ponad 3 metry", "Ponad 8 metrów"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-078', 'Rekin sprzed stuleci', 'Zwierzęta', 'Rekin grenlandzki może dożyć około 400 lat.', 'To najdłużej żyjący znany kręgowiec. Wiek ustalono datowaniem radiowęglowym soczewki oka, która powstaje jeszcze przed narodzinami.

Rekin rośnie bardzo wolno i prawdopodobnie osiąga dojrzałość dopiero po około 150 latach.', 'Nielsen i in., „Eye lens radiocarbon reveals centuries of longevity in the Greenland shark”, Science, 2016', null, '{"question": "Jak ustalono wiek rekina grenlandzkiego?", "options": ["Datując soczewkę oka", "Licząc pierścienie na płetwie", "Licząc zęby"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-079', 'Odciski palców koali', 'Zwierzęta', 'Koale mają odciski palców bardzo podobne do ludzkich.', 'Są tak podobne, że nawet pod mikroskopem trudno je odróżnić. Co ciekawe, koale nie są naszymi bliskimi krewnymi: to torbacze.

Podobne linie papilarne wykształciły się niezależnie, prawdopodobnie jako pomoc w chwytaniu gałęzi i liści.', 'Henneberg, Lambert i Leigh, „Fingerprints of a koala”, Journal of Forensic Identification, 1997', null, '{"question": "Do jakiej grupy zwierząt należą koale?", "options": ["Do torbaczy", "Do naczelnych", "Do niedźwiedzi"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-080', 'Nieśmiertelna meduza', 'Zwierzęta', 'Pewien gatunek meduzy potrafi wrócić do młodszego stadium życia.', 'Turritopsis dohrnii w razie stresu lub uszkodzenia zamienia się z dorosłej meduzy z powrotem w polip, czyli formę młodocianą.

Cykl może się powtarzać, dlatego nazywa się ją nieśmiertelną. W praktyce wiele osobników ginie, pożeranych przez inne zwierzęta lub z powodu chorób.', 'Encyclopaedia Britannica, hasło „Immortal jellyfish”', null, '{"question": "W co zamienia się meduza Turritopsis dohrnii?", "options": ["W polip, czyli formę młodocianą", "W ukwiała", "W małą rybę"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-081', 'Ojciec na lodzie', 'Zwierzęta', 'Samiec pingwina cesarskiego wysiaduje jajo przez około dwa miesiące, nic nie jedząc.', 'Samica składa jajo i wraca do morza, a samiec trzyma je na stopach, pod fałdem skóry, podczas antarktycznej zimy.

W tym czasie może stracić nawet około 40% masy ciała. Ptaki chronią się przed mrozem, stojąc w ciasnych grupach.', 'Encyclopaedia Britannica, hasło „Emperor penguin”', null, '{"question": "Gdzie samiec pingwina cesarskiego trzyma jajo?", "options": ["Na stopach, pod fałdem skóry", "W norze pod śniegiem", "W gnieździe z kamieni"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-082', 'Delfiny mają imiona', 'Zwierzęta', 'Każdy delfin ma własny gwizd, który działa podobnie jak imię.', 'Młode delfiny butlonose wykształcają charakterystyczny gwizd i używają go, by się przedstawić.

Badania pokazały, że delfiny reagują, gdy usłyszą własny sygnał, a naśladując gwizd innego osobnika, mogą się do niego zwracać.', 'King i Janik, „Bottlenose dolphins can use learned vocal labels to address each other”, PNAS, 2013', null, '{"question": "Co u delfinów działa podobnie jak imię?", "options": ["Charakterystyczny gwizd", "Kształt płetwy", "Sposób skakania"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-083', 'Jedyne latające ssaki', 'Zwierzęta', 'Nietoperze to jedyne ssaki zdolne do prawdziwego, aktywnego lotu.', 'Ich skrzydła to błona rozpięta między bardzo długimi palcami, co daje im dużą zwrotność w powietrzu.

Lotopałanki czy polatuchy jedynie szybują. Na świecie żyje ponad 1400 gatunków nietoperzy, czyli około jedna piąta wszystkich ssaków.', 'Encyclopaedia Britannica, hasło „Bat”', null, '{"question": "Co tworzy skrzydło nietoperza?", "options": ["Wydłużone żebra", "Błona między długimi palcami", "Pióra na przednich łapach"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-084', 'Mocniejszy niż stal', 'Zwierzęta', 'Pajęcza nić przy tej samej masie bywa wytrzymalsza niż stal.', 'Nici pajęcze są jednocześnie mocne i rozciągliwe, co sprawia, że pochłaniają dużo energii bez zerwania.

Naukowcy od lat próbują odtworzyć ten materiał w laboratorium, bo mógłby się przydać w medycynie czy tekstyliach.', 'Encyclopaedia Britannica, hasło „Spider”', null, '{"question": "Jaką cechę pajęczej nici łączy z mocą?", "options": ["Przewodzenie prądu", "Rozciągliwość", "Twardość szkła"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-085', 'Kot, który nie ryczy', 'Zwierzęta', 'Gepard nie potrafi ryczeć, za to mruczy jak duży kot domowy.', 'Budowa krtani gepardów sprawia, że wydają mruczenie i ćwierkanie, a nie ryk jak lwy czy tygrysy.

To najszybsze zwierzę lądowe, ale pełną prędkość, około 100 km/h, utrzymuje tylko przez kilkanaście sekund sprintu.', 'Encyclopaedia Britannica, hasło „Cheetah”', null, '{"question": "Jaki dźwięk wydaje gepard?", "options": ["Mruczy", "Ryczy", "Wyje"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-086', 'Najszybsze zwierzę świata', 'Zwierzęta', 'Sokół wędrowny w locie nurkowym przekracza 300 km/h.', 'Ptak składa skrzydła i spada na zdobycz z dużej wysokości. To najszybszy znany ruch żyjącego zwierzęcia.

Stożkowate wyrostki w nozdrzach pomagają mu oddychać przy tak ogromnej prędkości. Sokoły wędrowne gniazdują też na budynkach w polskich miastach.', 'Encyclopaedia Britannica, hasło „Peregrine falcon”', null, '{"question": "Jaką prędkość osiąga nurkujący sokół wędrowny?", "options": ["Ponad 300 km/h", "Około 1000 km/h", "Około 60 km/h"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-087', 'Samiec przyczepiony do samicy', 'Zwierzęta', 'Samce niektórych żabnic głębinowych zrastają się z ciałem samicy.', 'W ciemnych głębinach trudno znaleźć partnerkę, więc maleńki samiec wgryza się w znacznie większą samicę, gdy już ją spotka.

U części gatunków łączą się ich układy krwionośne, a samiec do końca życia służy jako źródło nasienia.', 'Encyclopaedia Britannica, hasło „Anglerfish”', null, '{"question": "Co robi samiec niektórych żabnic po znalezieniu samicy?", "options": ["Zrasta się z jej ciałem", "Buduje gniazdo", "Zjada ją"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-088', 'Szczury się śmieją', 'Zwierzęta', 'Łaskotane szczury wydają ultradźwięki przypominające śmiech.', 'Neuronaukowiec Jaak Panksepp zauważył, że szczury podczas zabawy wydają piski o wysokiej częstotliwości, niesłyszalne dla człowieka.

Łaskotane zwierzęta wracały do ręki badacza po więcej. Badania nad tym zjawiskiem pomagają zrozumieć pozytywne emocje.', 'Panksepp i Burgdorf, „Laughing rats and the evolutionary antecedents of human joy?”, Physiology & Behavior, 2003', null, '{"question": "Dlaczego człowiek nie słyszy śmiechu szczurów?", "options": ["Jest zbyt niski", "Jest to ultradźwięk", "Szczury śmieją się tylko w norach"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-089', 'Słoń przed lustrem', 'Zwierzęta', 'Słonie azjatyckie potrafią rozpoznać się w lustrze.', 'W eksperymencie słoniom namalowano na głowie znak, widoczny tylko w odbiciu. Jedna ze słonic dotykała go trąbą, patrząc w lustro.

Test samorozpoznania przeszły nieliczne gatunki, między innymi człowiekowate, delfiny i sroki.', 'Plotnik, de Waal i Reiss, „Self-recognition in an Asian elephant”, PNAS, 2006', null, '{"question": "Co zrobiła słonica w teście z lustrem?", "options": ["Dotknęła znaku na swojej głowie", "Zaczęła czyścić odbicie wodą", "Rozbiła lustro"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-090', 'Pomarańczowe zęby bobra', 'Zwierzęta', 'Zęby bobra są pomarańczowe, bo szkliwo zawiera żelazo.', 'Związki żelaza wzmacniają szkliwo i czynią je odporniejszym, co przydaje się przy ścinaniu drzew.

Siekacze bobrów rosną przez całe życie, a stale się ścierając, pozostają ostre. Bobry w Polsce zniknęły niemal całkowicie, ale wróciły dzięki reintrodukcji.', 'Gordon i in., „Amorphous intergranular phases control the properties of rodent tooth enamel”, Science, 2015', null, '{"question": "Dlaczego zęby bobra są pomarańczowe?", "options": ["Bóbr jada dużo marchwi", "Szkliwo zawiera żelazo", "Barwi je kora drzew"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-091', 'Mur, którego nie widać', 'Historia', 'Wielkiego Muru Chińskiego praktycznie nie widać gołym okiem z kosmosu.', 'Popularne twierdzenie jest mitem: mur jest wprawdzie bardzo długi, ale wąski i zlewa się z otoczeniem.

Chiński astronauta Yang Liwei po locie w 2003 roku powiedział, że nie zdołał go dostrzec.', 'Encyclopaedia Britannica, hasło „Great Wall of China”', null, '{"question": "Dlaczego muru trudno dostrzec z kosmosu?", "options": ["Zawsze zakrywają go chmury", "Jest wąski i zlewa się z otoczeniem", "Większość muru leży pod ziemią"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-092', 'Tulipanowa gorączka', 'Historia', 'W XVII-wiecznej Holandii cebulki tulipanów bywały warte tyle co dom.', 'Na początku lat 30. XVII wieku ceny rzadkich odmian gwałtownie rosły, a handlowano nawet cebulkami jeszcze tkwiącymi w ziemi.

W lutym 1637 roku rynek załamał się. Historycy spierają się dziś, jak poważne były skutki, ale tulipanomania pozostała symbolem bańki spekulacyjnej.', 'Encyclopaedia Britannica, hasło „Tulip mania”', null, '{"question": "W którym roku załamał się rynek tulipanów?", "options": ["W 1837", "W 1537", "W 1637"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-093', 'Dziesięć dni, których nie było', 'Historia', 'W Polsce po 4 października 1582 roku nastąpił od razu 15 października.', 'Papież Grzegorz XIII zreformował kalendarz, bo stary rozmijał się z rokiem słonecznym. Trzeba było pominąć dziesięć dni.

Polska należała do pierwszych krajów, które przyjęły zmianę. Rosja zrobiła to dopiero w 1918 roku.', 'Encyclopaedia Britannica, hasło „Gregorian calendar”', null, '{"question": "Ile dni pominięto przy zmianie kalendarza w 1582 roku?", "options": ["Trzy", "Trzydzieści", "Dziesięć"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-094', 'Miasto w ogniu', 'Historia', 'Wielki pożar Londynu z 1666 roku zniszczył większość miasta, a oficjalnie zginęło kilka osób.', 'Ogień wybuchł w piekarni przy Pudding Lane i przez kilka dni trawił około 13 tysięcy domów oraz katedrę św. Pawła.

Zapisy podają tylko kilka ofiar, choć historycy uważają, że rzeczywista liczba mogła być wyższa, bo nie odnotowywano biednych mieszkańców.', 'Encyclopaedia Britannica, hasło „Great Fire of London”', null, '{"question": "Gdzie wybuchł wielki pożar Londynu?", "options": ["W porcie", "W piekarni", "W kościele"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-095', 'Niedźwiedź Wojtek', 'Historia', 'Niedźwiedź Wojtek był oficjalnie żołnierzem Armii Andersa.', 'Polscy żołnierze przygarnęli niedźwiadka w 1942 roku na Bliskim Wschodzie. Aby mógł płynąć do Włoch, wpisano go na stan 22. Kompanii Zaopatrywania Artylerii.

Podczas bitwy o Monte Cassino miał nosić skrzynie z amunicją. Po wojnie zamieszkał w zoo w Edynburgu.', 'Encyclopaedia Britannica, hasło „Wojtek”', null, '{"question": "W czasie jakiej bitwy Wojtek miał nosić amunicję?", "options": ["Pod Grunwaldem", "Pod Monte Cassino", "Pod Waterloo"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-096', 'Pompeje pod popiołem', 'Historia', 'Wybuch Wezuwiusza w 79 roku n.e. zachował całe rzymskie miasto.', 'Pompeje zostały zasypane warstwą pyłu i pumeksu, która przetrwała wieki. Dzięki temu archeolodzy znajdują tam domy, malowidła, a nawet chleby w piecach.

Miasto na nowo odkryto w XVIII wieku, a wykopaliska trwają do dziś.', 'Encyclopaedia Britannica, hasło „Pompeii”', null, '{"question": "Jaki wulkan zniszczył Pompeje?", "options": ["Etna", "Wezuwiusz", "Krakatau"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-097', 'Wikingowie przed Kolumbem', 'Historia', 'Wikingowie dotarli do Ameryki około 500 lat przed Kolumbem.', 'Pozostałości ich osady odkryto na Nowej Fundlandii, w L’Anse aux Meadows. Analiza drewna ściętego żelaznymi narzędziami wskazuje na 1021 rok.

Osada nie przetrwała długo, a Europa nie dowiedziała się wtedy o nowym lądzie.', 'Kuitems i in., „Evidence for European presence in the Americas in AD 1021”, Nature, 2021', null, '{"question": "Gdzie odkryto osadę wikingów w Ameryce?", "options": ["W Meksyku", "Na Nowej Fundlandii", "Na Florydzie"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-098', 'Wojna futbolowa', 'Historia', 'W 1969 roku Salwador i Honduras starły się w tzw. wojnie futbolowej.', 'Zamieszki wokół meczów eliminacji mistrzostw świata spotęgowały napięcia wywołane sporami o ziemię i migrację.

Walki trwały około 100 godzin. Mecze nie były prawdziwą przyczyną konfliktu, ale dały mu nazwę.', 'Encyclopaedia Britannica, hasło „Football War”', null, '{"question": "Ile trwała wojna futbolowa?", "options": ["Około 100 dni", "Dwa lata", "Około 100 godzin"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-099', 'Świńska wojna', 'Historia', 'W 1859 roku USA i Wielka Brytania niemal stanęły do wojny przez świnię.', 'Na wyspie San Juan amerykański farmer zastrzelił świnię należącą do brytyjskiej firmy, bo ryła w jego ogrodzie. Spór o zwierzę zaostrzył kwestię granicy.

Obie strony wysłały wojsko, ale nie padł ani jeden strzał do ludzi. Jedyną ofiarą była świnia.', 'U.S. National Park Service, „The Pig War”', null, '{"question": "Kto był jedyną ofiarą świńskiej wojny?", "options": ["Brytyjski oficer", "Świnia", "Farmer"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-100', 'Fala melasy', 'Historia', 'W 1919 roku przez Boston przetoczyła się śmiertelna fala melasy.', 'Zbiornik z ponad 8 milionami litrów syropu pękł w styczniu i zalał ulice falą wysoką na kilka metrów.

Zginęło 21 osób, a około 150 odniosło obrażenia. Katastrofa doprowadziła do zaostrzenia zasad nadzoru nad budowlami.', 'Encyclopaedia Britannica, hasło „Boston Molasses Flood”', null, '{"question": "Co zalało ulice Bostonu w 1919 roku?", "options": ["Piwo", "Mleko", "Melasa"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-101', 'Odsiecz wiedeńska', 'Historia', 'W 1683 roku wojska Jana III Sobieskiego rozbiły Turków pod Wiedniem.', 'Oblężone miasto było na skraju upadku, gdy król poprowadził sprzymierzone wojska. Kluczowa była wielka szarża jazdy z husarią na czele.

Zwycięstwo zatrzymało ekspansję Imperium Osmańskiego w głąb Europy.', 'Encyclopaedia Britannica, hasło „Siege of Vienna”', null, '{"question": "Kto dowodził odsieczą Wiednia?", "options": ["Władysław Jagiełło", "Jan III Sobieski", "Stefan Batory"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-102', 'Kopernik od pieniędzy', 'Historia', 'Mikołaj Kopernik był nie tylko astronomem, ale też ekonomistą i lekarzem.', 'W traktacie o monecie opisał zjawisko wypierania lepszego pieniądza przez gorszy, znane dziś jako prawo Kopernika-Greshama.

Pracował jako kanonik, leczył ludzi i zarządzał majątkiem kapituły warmińskiej, a w 1520 roku bronił zamku w Olsztynie.', 'Encyclopaedia Britannica, hasło „Nicolaus Copernicus”', null, '{"question": "Co opisuje prawo Kopernika-Greshama?", "options": ["Ruch planet wokół Słońca", "Działanie soczewek", "Wypieranie lepszego pieniądza przez gorszy"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-103', 'Kamień z Rosetty', 'Historia', 'Jeden kamień pozwolił odczytać hieroglify po wiekach zapomnienia.', 'Znaleziony w 1799 roku kamień zawierał ten sam tekst w trzech pismach: hieroglificznym, demotycznym i greckim.

Dzięki znajomości greki Jean-François Champollion rozszyfrował hieroglify w 1822 roku. Dziś zabytek można oglądać w British Museum.', 'British Museum, „Everything you ever wanted to know about the Rosetta Stone”', null, '{"question": "Kto rozszyfrował hieroglify?", "options": ["Napoleon Bonaparte", "Howard Carter", "Jean-François Champollion"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-104', 'Ministerstwo edukacji', 'Historia', 'Polska Komisja Edukacji Narodowej z 1773 roku bywa nazywana pierwszym ministerstwem oświaty.', 'Powołano ją po kasacie zakonu jezuitów, który wcześniej prowadził wiele szkół. Komisja przejęła jego majątek i zreformowała nauczanie.

Wprowadziła między innymi nowe podręczniki i naukę po polsku. Na jej pamiątkę 14 października obchodzimy Dzień Edukacji Narodowej.', 'Encyclopaedia Britannica, hasło „Commission of National Education”', null, '{"question": "Kiedy obchodzimy Dzień Edukacji Narodowej?", "options": ["1 września", "3 maja", "14 października"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-105', 'Konfederacja warszawska', 'Historia', 'W 1573 roku szlachta polska zagwarantowała sobie pokój między wyznaniami.', 'Akt przyjęto w okresie, gdy w innych częściach Europy trwały krwawe wojny religijne. Rok wcześniej we Francji doszło do nocy św. Bartłomieja.

Dokument wpisano w 2003 roku na listę UNESCO Pamięć Świata.', 'UNESCO Memory of the World, „Warsaw Confederation”', null, '{"question": "Co gwarantowała konfederacja warszawska?", "options": ["Wolny handel zbożem", "Wybór króla przez mieszczan", "Pokój między wyznaniami"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-106', 'Słonie w Alpach', 'Historia', 'Hannibal przeprowadził przez Alpy armię ze słoniami bojowymi.', 'W 218 roku p.n.e. kartagiński wódz wyruszył z Hiszpanii, by zaatakować Rzym od północy. Przeprawa kosztowała go wielu ludzi i zwierząt.

Mimo to odniósł we Włoszech wielkie zwycięstwa, takie jak bitwa pod Kannami.', 'Encyclopaedia Britannica, hasło „Hannibal”', null, '{"question": "Z jakiego państwa pochodził Hannibal?", "options": ["Z Kartaginy", "Z Egiptu", "Z Grecji"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-107', 'Powieść o Titanie', 'Historia', 'W 1898 roku wydano powieść o wielkim statku Titan, który tonie po zderzeniu z górą lodową.', 'Morgan Robertson opisał w niej ogromny, rzekomo niezatapialny liniowiec z niewystarczającą liczbą szalup, 14 lat przed katastrofą Titanica.

Podobieństwa są uderzające, ale wynikają z logicznego przewidywania rozwoju żeglugi, a nie z proroctwa.', 'Encyclopaedia Britannica, hasło „Titanic”', null, '{"question": "Jak nazywał się statek z powieści z 1898 roku?", "options": ["Olympic", "Poseidon", "Titan"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-108', 'Biblia Gutenberga', 'Historia', 'Około 1455 roku Johannes Gutenberg wydrukował swoją słynną Biblię.', 'Dzięki ruchomym czcionkom powstało około 180 egzemplarzy, co dla ręcznych kopistów byłoby pracą na wiele lat.

Do dziś przetrwało mniej niż 50 kopii, w całości lub części. Jedna z nich jest w Polsce, w Muzeum Diecezjalnym w Pelplinie.', 'Encyclopaedia Britannica, hasło „Gutenberg Bible”', null, '{"question": "Gdzie w Polsce znajduje się Biblia Gutenberga?", "options": ["W Gnieźnie", "W Pelplinie", "W Toruniu"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-109', 'Cesarz Stanów Zjednoczonych', 'Historia', 'W 1859 roku Joshua Norton ogłosił się cesarzem Stanów Zjednoczonych.', 'Ten zbankrutowany kupiec z San Francisco wydawał dekrety i własne banknoty, które lokalne sklepy często przyjmowały.

Mieszkańcy traktowali go z sympatią. Gdy zmarł w 1880 roku, na pogrzeb przyszły tysiące ludzi.', 'Encyclopaedia Britannica, hasło „Emperor Norton”', null, '{"question": "W jakim mieście żył cesarz Norton?", "options": ["W Nowym Jorku", "W San Francisco", "W Chicago"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-110', 'Zaćmienie Kolumba', 'Historia', 'Kolumb wykorzystał zaćmienie Księżyca, by przekonać mieszkańców Jamajki do pomocy.', 'W 1504 roku rozbitkowie zostali bez zapasów. Kolumb znał z tablic astronomicznych datę zaćmienia i ostrzegł, że Bóg zabierze Księżyc.

Gdy tarcza zaczęła ciemnieć, wystraszeni mieszkańcy znów zaczęli dostarczać żywność.', 'Encyclopaedia Britannica, hasło „Christopher Columbus”', null, '{"question": "Skąd Kolumb znał datę zaćmienia?", "options": ["Z obserwacji gwiazd poprzedniej nocy", "Z tablic astronomicznych", "Od tubylców"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-111', 'Placebo bez ukrywania', 'Psychologia', 'Placebo może pomagać, nawet gdy pacjent wie, że to placebo.', 'W badaniu z 2010 roku pacjenci z zespołem jelita drażliwego dostali tabletki otwarcie opisane jako niezawierające leku. Mimo to zgłaszali wyraźną poprawę.

Nie znaczy to, że placebo leczy choroby. Wpływa głównie na odczuwanie objawów, na przykład bólu.', 'Kaptchuk i in., „Placebos without Deception”, PLoS ONE, 2010', null, '{"question": "Na co działa placebo przede wszystkim?", "options": ["Na same przyczyny chorób", "Na kolor skóry", "Na odczuwanie objawów"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-112', 'Magiczna siódemka', 'Psychologia', 'Pamięć krótkotrwała mieści zaskakująco mało elementów naraz.', 'George Miller w 1956 roku opisał, że ludzie pamiętają około 7 elementów, plus minus 2. Późniejsze badania wskazują raczej na około 4.

Dlatego łatwiej zapamiętać numer telefonu podzielony na grupy cyfr.', 'George A. Miller, „The Magical Number Seven, Plus or Minus Two”, Psychological Review, 1956', null, '{"question": "Co ułatwia zapamiętanie długiego numeru?", "options": ["Czytanie go wspak", "Zapisywanie małymi cyframi", "Podział na grupy cyfr"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-113', 'Ślinka na dźwięk', 'Psychologia', 'Psy Pawłowa zaczęły się ślinić na sam sygnał zapowiadający jedzenie.', 'Iwan Pawłow badał trawienie i zauważył, że psy reagują jeszcze przed podaniem karmy. Gdy łączył jedzenie z bodźcem, ten bodziec sam zaczynał wywoływać reakcję.

Tak opisano warunkowanie klasyczne. Pawłow otrzymał Nobla w 1904 roku, ale za badania nad trawieniem.', 'Nobel Prize, „Ivan Pavlov – Facts”', null, '{"question": "Za co Pawłow otrzymał Nagrodę Nobla?", "options": ["Za odkrycie witamin", "Za badania nad trawieniem", "Za warunkowanie klasyczne"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-114', 'Posłuszni aż do końca', 'Psychologia', 'W eksperymencie Milgrama 65% osób doszło na polecenie badacza do najsilniejszego wstrząsu.', 'Uczestnicy sądzili, że karzą inną osobę prądem za błędy. Wstrząsy były udawane, ale oni o tym nie wiedzieli.

Do końca skali aparatu doszło aż 65% badanych w głównej wersji badania z 1963 roku. Wyniki i metoda są do dziś szeroko dyskutowane.', 'Stanley Milgram, „Behavioral Study of Obedience”, Journal of Abnormal and Social Psychology, 1963', null, '{"question": "Czy wstrząsy w eksperymencie Milgrama były prawdziwe?", "options": ["Nie, były udawane", "Tak, dla wszystkich", "Tak, ale bardzo słabe"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-115', 'Kolor kontra słowo', 'Psychologia', 'Trudniej nazwać kolor słowa „czerwony” zapisanego na niebiesko.', 'Efekt Stroopa, opisany w 1935 roku, pokazuje, że czytanie jest u dorosłych niemal automatyczne i przeszkadza w nazwaniu koloru.

Test wciąż służy do badania uwagi i kontroli poznawczej.', 'J. Ridley Stroop, „Studies of interference in serial verbal reactions”, Journal of Experimental Psychology, 1935', null, '{"question": "Co utrudnia wykonanie zadania w efekcie Stroopa?", "options": ["Mała czcionka", "Automatyczne czytanie", "Ślepota barw"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-116', 'Oczekiwania nauczyciela', 'Psychologia', 'Oczekiwania nauczycieli mogą wpływać na wyniki uczniów.', 'Rosenthal i Jacobson powiedzieli nauczycielom, że wybrani uczniowie wkrótce rozkwitną, choć wybrano ich losowo. Niektórzy z nich osiągnęli później wyraźniejsze postępy.

To efekt Pigmaliona. Jego siła jest przedmiotem sporu, ale pokazuje wagę tego, czego się po kimś spodziewamy.', 'Rosenthal i Jacobson, „Pygmalion in the Classroom”, 1968', null, '{"question": "Jak wybrano uczniów w badaniu efektu Pigmaliona?", "options": ["Losowo", "Według wieku", "Według najlepszych ocen"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-117', 'Test pianki', 'Psychologia', 'Dzieci w teście pianki mogły dostać dwa słodycze, jeśli poczekały na powrót badacza.', 'Walter Mischel badał w latach 60. i 70. XX wieku odraczanie nagrody. Dzieci, które dłużej czekały, po latach często wypadały lepiej w różnych miarach.

Replikacja z 2018 roku wykazała jednak dużo słabszy związek, gdy wzięto pod uwagę pochodzenie rodziny.', 'Watts, Duncan i Quan, „Revisiting the Marshmallow Test”, Psychological Science, 2018', null, '{"question": "Co wykazała replikacja testu pianki z 2018 roku?", "options": ["Dużo silniejszy związek", "Dużo słabszy związek", "Dzieci nie lubią pianek"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-118', 'Linie Ascha', 'Psychologia', 'Ludzie potrafią zgodzić się z grupą, nawet gdy widzą, że nie ma racji.', 'Solomon Asch prosił o porównanie długości linii. Inni uczestnicy byli podstawieni i celowo podawali złą odpowiedź.

Około trzech czwartych badanych co najmniej raz dostosowało się do grupy, choć poprawna odpowiedź była oczywista.', 'Solomon Asch, „Effects of group pressure upon the modification and distortion of judgments”, 1951', null, '{"question": "Co oceniali uczestnicy badań Ascha?", "options": ["Długość linii", "Smak napojów", "Wagę przedmiotów"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-119', 'Krzywa zapominania', 'Psychologia', 'Większość nowego materiału zapominamy szybko, chyba że do niego wrócimy.', 'Hermann Ebbinghaus badał na sobie zapamiętywanie bezsensownych sylab i opisał krzywą zapominania w 1885 roku.

Najwięcej tracimy zaraz po nauce, ale każde powtórzenie spowalnia ten proces. To dlatego Dziesiątka wraca do starszych kart.', 'Hermann Ebbinghaus, „Über das Gedächtnis”, 1885', null, '{"question": "Co spowalnia zapominanie?", "options": ["Dłuższy sen w dzień", "Powtórki", "Picie kawy podczas nauki"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-120', 'Efekt aureoli', 'Psychologia', 'Jedna pozytywna cecha potrafi poprawić ocenę całej osoby.', 'Edward Thorndike zauważył w 1920 roku, że dowódcy, oceniając żołnierzy, łączyli niezależne cechy. Ten, kto dobrze wyglądał, był też oceniany jako inteligentniejszy.

Efekt aureoli działa też w reklamie i podczas rozmów o pracę.', 'Edward Thorndike, „A constant error in psychological ratings”, Journal of Applied Psychology, 1920', null, '{"question": "Kto opisał efekt aureoli?", "options": ["Carl Jung", "Edward Thorndike", "Sigmund Freud"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-121', 'Liczba Dunbara', 'Psychologia', 'Człowiek utrzymuje bliższe relacje z około 150 osobami.', 'Antropolog Robin Dunbar wyliczył tę wartość, porównując rozmiary mózgu i grup społecznych u naczelnych.

Liczba przyjęła się w opisie firm i wojska, choć część badaczy kwestionuje jej dokładność. Nie jest to twarda granica.', 'R. I. M. Dunbar, „Neocortex size as a constraint on group size in primates”, Journal of Human Evolution, 1992', null, '{"question": "Ile bliższych relacji zakłada liczba Dunbara?", "options": ["Około 1500", "Około 15", "Około 150"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-122', 'Pułapka utopionych kosztów', 'Psychologia', 'Często trwamy przy złej decyzji tylko dlatego, że już dużo w nią włożyliśmy.', 'Arkes i Blumer pokazali w 1985 roku, że ludzie częściej wybierają gorszą opcję, jeśli wcześniej za nią zapłacili.

Dlatego oglądamy nudny film do końca, skoro kupiliśmy bilet. Racjonalnie liczą się tylko przyszłe korzyści.', 'Arkes i Blumer, „The Psychology of Sunk Cost”, Organizational Behavior and Human Decision Processes, 1985', null, '{"question": "Co zgodnie z logiką powinno liczyć się przy decyzji?", "options": ["Wcześniej poniesione koszty", "Opinie znajomych", "Przyszłe korzyści"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-123', 'Strata boli bardziej', 'Psychologia', 'Strata 100 zł boli bardziej, niż cieszy zysk 100 zł.', 'Kahneman i Tversky opisali awersję do strat w teorii perspektywy z 1979 roku. Ból straty bywa szacowany na około dwa razy silniejszy niż radość z takiego samego zysku.

Za te badania Kahneman otrzymał w 2002 roku Nagrodę Nobla z ekonomii.', 'Kahneman i Tversky, „Prospect Theory”, Econometrica, 1979', null, '{"question": "Za co Kahneman otrzymał Nagrodę Nobla?", "options": ["Za odkrycia w fizyce", "Za badania nad decyzjami i ryzykiem", "Za pokój na świecie"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-124', 'Lepsi niż przeciętni', 'Psychologia', 'Większość kierowców uważa, że jeździ lepiej niż przeciętny kierowca.', 'W badaniu Ole Svensona z 1981 roku aż 93% badanych Amerykanów uznało się za kierowców lepszych od mediany.

To efekt ponadprzeciętności: statystycznie nie może być prawdą, by tak liczna grupa przekraczała środek stawki.', 'Ole Svenson, „Are we all less risky and more skillful than our fellow drivers?”, Acta Psychologica, 1981', null, '{"question": "Jaki odsetek badanych Amerykanów uznał się za lepszych kierowców?", "options": ["93%", "53%", "23%"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-125', 'Wspomnienie zmienione pytaniem', 'Psychologia', 'Samo sformułowanie pytania może zmienić to, co pamiętamy.', 'Elizabeth Loftus pokazywała film z wypadkiem i pytała o prędkość aut. Gdy użyła słowa „roztrzaskały się”, ludzie szacowali ją wyżej niż przy „zderzyły się”.

Badania te mają duże znaczenie dla oceny zeznań świadków w sądzie.', 'Loftus i Palmer, „Reconstruction of automobile destruction”, Journal of Verbal Learning and Verbal Behavior, 1974', null, '{"question": "Na jaką dziedzinę szczególnie wpływają badania Loftus?", "options": ["Na ocenę zeznań w sądzie", "Na architekturę", "Na medycynę sportową"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-126', 'Horoskop dla każdego', 'Psychologia', 'Ogólnikowy opis osobowości często wydaje się ludziom trafny.', 'Bertram Forer dał studentom rzekomo indywidualny opis osobowości. Wszyscy dostali ten sam tekst, a mimo to oceniali go jako bardzo dokładny.

To efekt Barnuma, na którym opierają się horoskopy i wróżby.', 'Bertram R. Forer, „The fallacy of personal validation”, Journal of Abnormal and Social Psychology, 1949', null, '{"question": "Co dostali studenci w badaniu Forera?", "options": ["Testy IQ", "Własne horoskopy", "Ten sam tekst"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-127', 'Wyuczona bezradność', 'Psychologia', 'Po serii porażek nie do uniknięcia można przestać próbować, nawet gdy pojawi się wyjście.', 'Martin Seligman opisał to zjawisko w badaniach z lat 60. XX wieku, początkowo prowadzonych na psach.

Później wiązano je z depresją, a sam Seligman rozwinął psychologię pozytywną, skupioną na tym, co pomaga ludziom rozkwitać.', 'Seligman i Maier, „Failure to escape traumatic shock”, Journal of Experimental Psychology, 1967', null, '{"question": "Jaki nurt rozwinął później Martin Seligman?", "options": ["Psychologię pozytywną", "Behawioryzm radykalny", "Psychoanalizę"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-128', 'Iluzja częstości', 'Psychologia', 'Po poznaniu nowego słowa nagle wydaje się, że jest ono wszędzie.', 'To iluzja częstości, znana też jako fenomen Baadera-Meinhof. Słowo nie pojawia się częściej, tylko zaczynamy je zauważać.

Podobnie po kupnie czerwonego auta nagle wszędzie widzimy czerwone samochody.', 'Arnold Zwicky, „Just Between Dr. Language and I”, Language Log, 2005', null, '{"question": "Co naprawdę zmienia się w iluzji częstości?", "options": ["To, co zauważamy", "Liczba wystąpień słowa", "Ilość snu"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-129', 'Efekt przyjęcia', 'Psychologia', 'W gwarnym pomieszczeniu wyłapujemy własne imię wypowiedziane po drugiej stronie sali.', 'Colin Cherry opisał w 1953 roku, jak potrafimy skupić się na jednej rozmowie, ignorując resztę.

Mózg nie wyłącza jednak zupełnie pozostałych dźwięków. Ważne bodźce, takie jak imię, mogą przebić się przez filtr uwagi.', 'E. Colin Cherry, „Some experiments on the recognition of speech”, Journal of the Acoustical Society of America, 1953', null, '{"question": "Co często przebija się przez filtr uwagi?", "options": ["Szum klimatyzacji", "Własne imię", "Stukot sztućców"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-130', 'Gumowa ręka', 'Psychologia', 'Mózg można przekonać, że gumowa ręka należy do ciała.', 'Uczestnikowi chowa się prawdziwą dłoń, a przed nim kładzie gumową. Gdy obie są jednocześnie głaskane, po chwili czuje dotyk na sztucznej ręce.

Eksperyment z 1998 roku pokazuje, że poczucie własnego ciała powstaje z połączenia wzroku i dotyku.', 'Botvinick i Cohen, „Rubber hands ‘feel’ touch that eyes see”, Nature, 1998', null, '{"question": "Co wywołuje iluzję gumowej ręki?", "options": ["Zimna woda", "Jednoczesne głaskanie obu dłoni", "Głośna muzyka"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-131', 'Pierwsza strona WWW', 'Technologia', 'Pierwszą stronę internetową opublikowano w 1991 roku w CERN.', 'Tim Berners-Lee opracował WWW, by naukowcy mogli łatwiej dzielić się informacjami. Pierwsza strona wyjaśniała, czym jest ten projekt.

W 1993 roku CERN udostępnił technologię bezpłatnie, co pozwoliło jej rozejść się po świecie.', 'CERN, „A short history of the Web”', null, '{"question": "Gdzie powstała pierwsza strona WWW?", "options": ["W Google", "W CERN", "W NASA"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-132', 'Pierwszy spam', 'Technologia', 'Pierwszy spam wysłano w 1978 roku do kilkuset użytkowników sieci ARPANET.', 'Gary Thuerk z firmy DEC reklamował w ten sposób nowe komputery. Wiadomość rozzłościła odbiorców, ale podobno przyniosła sprzedaż.

Słowo „spam” przyjęło się później, między innymi za sprawą skeczu Monty Pythona.', 'Encyclopaedia Britannica, hasło „Spam”', null, '{"question": "Co reklamował pierwszy spam?", "options": ["Bilety lotnicze", "Komputery", "Leki"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-133', 'Pierwsza programistka', 'Technologia', 'Ada Lovelace napisała algorytm dla maszyny, której nigdy nie zbudowano.', 'W 1843 roku opisała, jak Maszyna Analityczna Charlesa Babbage’a mogłaby obliczać liczby Bernoulliego. Często uznaje się to za pierwszy program.

Lovelace przewidywała też, że maszyny mogłyby przetwarzać coś więcej niż liczby, na przykład muzykę.', 'Encyclopaedia Britannica, hasło „Ada Lovelace”', null, '{"question": "Czyją maszynę opisywała Ada Lovelace?", "options": ["Alana Turinga", "Thomasa Edisona", "Charlesa Babbage’a"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-134', '176 pierwszych emoji', 'Technologia', 'Pierwszy popularny zestaw emoji składał się ze 176 znaków.', 'Shigetaka Kurita zaprojektował je w 1999 roku dla japońskiego operatora NTT DoCoMo, w siatce 12 na 12 pikseli.

W 2016 roku zestaw trafił do kolekcji Museum of Modern Art w Nowym Jorku.', 'Museum of Modern Art, „Emoji (1998–1999), Shigetaka Kurita”', null, '{"question": "Gdzie trafił pierwszy zestaw emoji w 2016 roku?", "options": ["Do Luwru", "Do British Museum", "Do Museum of Modern Art"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-135', 'Telefon do konkurencji', 'Technologia', 'Pierwszą rozmowę z telefonu komórkowego przeprowadzono w 1973 roku do konkurenta.', 'Martin Cooper z Motoroli zadzwonił na ulicy w Nowym Jorku do Joela Engela z Bell Labs, by pochwalić się osiągnięciem.

Prototyp ważył około kilograma, a bateria pozwalała rozmawiać przez około pół godziny.', 'Encyclopaedia Britannica, hasło „Martin Cooper”', null, '{"question": "Dla jakiej firmy pracował Martin Cooper?", "options": ["Dla Apple", "Dla Motoroli", "Dla Nokii"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-136', 'Dysk ważący tonę', 'Technologia', 'Pierwszy dysk twardy z 1956 roku mieścił około 5 MB i ważył ponad tonę.', 'System IBM 305 RAMAC zajmował całą szafę, a dane zapisywano na 50 wirujących talerzach.

Dla porównania, jedno zdjęcie ze współczesnego telefonu może zająć tyle samo miejsca.', 'IBM, „RAMAC: The first hard disk drive”', null, '{"question": "Ile danych mieścił pierwszy dysk twardy?", "options": ["Około 5 GB", "Około 5 MB", "Około 500 MB"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-137', 'Programistki ENIAC-a', 'Technologia', 'Pierwszy duży komputer elektroniczny ważył około 30 ton, a programowały go kobiety.', 'ENIAC powstał w USA i zaprezentowano go w 1946 roku. Sześć programistek ustawiało go, przełączając kable i przełączniki.

Przez dekady ich wkład pomijano, a na zdjęciach brano je czasem za modelki.', 'Encyclopaedia Britannica, hasło „ENIAC”', null, '{"question": "Jak programowano ENIAC-a?", "options": ["Na klawiaturze dotykowej", "Za pomocą głosu", "Przełączając kable i przełączniki"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-138', 'Gwiazda filmowa i radio', 'Technologia', 'Aktorka Hedy Lamarr współtworzyła wynalazek ważny dla łączności bezprzewodowej.', 'W 1942 roku wraz z kompozytorem George’em Antheilem opatentowała skakanie po częstotliwościach, by chronić torpedy przed zagłuszaniem.

Pomysł nie został wtedy użyty, ale podobna zasada działa dziś w technologiach bezprzewodowych.', 'National Inventors Hall of Fame, „Hedy Lamarr”', null, '{"question": "Kim z zawodu była Hedy Lamarr?", "options": ["Aktorką", "Pilotką", "Lekarką"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-139', 'LO zamiast LOGIN', 'Technologia', 'Pierwsza wiadomość w sieci ARPANET brzmiała „LO”, bo system się zawiesił.', '29 października 1969 roku naukowcy z UCLA chcieli zalogować się do komputera w Stanford i wpisać LOGIN.

Po dwóch literach system padł. Kilka godzin później udało się przesłać całość. Tak zaczęła się historia internetu.', 'Computer History Museum, „ARPANET”', null, '{"question": "Co próbowano wpisać w pierwszej wiadomości ARPANET?", "options": ["LONDON", "HELLO", "LOGIN"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-140', 'Kod z fabryki aut', 'Technologia', 'Kody QR wymyślono w 1994 roku do śledzenia części samochodowych.', 'Stworzyła je japońska firma Denso Wave, związana z Toyotą. Kody mieszczą dużo więcej danych niż zwykły kod kreskowy.

Firma nie egzekwuje swojego patentu, dzięki czemu każdy może ich używać. Dziś służą do płatności i biletów.', 'Denso Wave, „History of QR Code”', null, '{"question": "Do czego pierwotnie służyły kody QR?", "options": ["Do płatności w sklepach", "Do biletów lotniczych", "Do śledzenia części samochodowych"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-141', 'Guma do żucia w historii', 'Technologia', 'Pierwszy zeskanowany w sklepie kod kreskowy był na gumie do żucia Wrigley’s.', 'Stało się to 26 czerwca 1974 roku w supermarkecie w Ohio. Paczkę gumy kupiono za 67 centów.

Ta pierwsza paczka trafiła później do zbiorów Smithsonian.', 'Smithsonian, „The Barcode”', null, '{"question": "Co zeskanowano jako pierwsze?", "options": ["Gumę do żucia", "Mleko", "Gazetę"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-142', 'Zespół z CERN', 'Technologia', 'Pierwsze zdjęcie w internecie przedstawiało żeński zespół muzyczny z CERN.', 'W 1992 roku Tim Berners-Lee poprosił kolegę o zdjęcie do strony WWW. Silvano de Gennaro udostępnił fotografię grupy Les Horribles Cernettes.

Zespół śpiewał zabawne piosenki o fizyce cząstek.', 'CERN, „Les Horribles Cernettes”', null, '{"question": "O czym śpiewały Les Horribles Cernettes?", "options": ["O fizyce cząstek", "O piłce nożnej", "O miłości w Paryżu"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-143', 'GPS i Einstein', 'Technologia', 'Bez teorii względności Einsteina GPS mylić by się o kilometry każdego dnia.', 'Słabsza grawitacja przyspiesza zegary na satelitach, a ich ruch orbitalny lekko je spowalnia. W sumie śpieszą się o około 38 mikrosekund na dobę.

Bez poprawek błędy pozycji narastałyby w tempie około 10 km dziennie.', 'Ohio State University, Richard Pogge, „GPS and Relativity”', null, '{"question": "O ile na dobę śpieszą się zegary GPS?", "options": ["O około 38 sekund", "O około 38 mikrosekund", "O około 38 minut"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-144', 'Rozpuszczona czekolada', 'Technologia', 'Kuchenkę mikrofalową wymyślono po tym, jak w kieszeni roztopił się batonik.', 'Inżynier Percy Spencer pracował przy radarach i zauważył to w latach 40. XX wieku. Sprawdził więc działanie mikrofal na kukurydzy.

Pierwsze modele firmy Raytheon były wysokie jak człowiek i ważyły ponad 300 kg.', 'Encyclopaedia Britannica, hasło „Percy Spencer”', null, '{"question": "Przy czym pracował Percy Spencer?", "options": ["Przy kuchenkach gazowych", "Przy lodówkach", "Przy radarach"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-145', 'To tylko hobby', 'Technologia', 'Twórca Linuksa zapowiedział go w 1991 roku jako projekt hobbystyczny.', 'Student Linus Torvalds napisał, że robi darmowy system „tylko dla hobby”, a nie coś wielkiego.

Dziś Linux działa na większości serwerów internetowych, a jego jądro jest podstawą Androida.', 'Encyclopaedia Britannica, hasło „Linux”', null, '{"question": "Czego podstawą jest jądro Linuksa?", "options": ["Androida", "iOS", "Windows"], "correctIndex": 0}'::jsonb, 'published'),
  ('fact-146', 'Python z telewizji', 'Technologia', 'Nazwa języka Python pochodzi od grupy komików, a nie od węża.', 'Guido van Rossum zaczął pracę nad językiem pod koniec lat 80. XX wieku. Nazwę wybrał na cześć brytyjskiego serialu „Latający cyrk Monty Pythona”.

W dokumentacji długo pojawiały się żarty nawiązujące do skeczy.', 'Python Software Foundation, „General Python FAQ”', null, '{"question": "Skąd pochodzi nazwa Python?", "options": ["Od gatunku węża", "Od greckiego boga", "Od Monty Pythona"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-147', 'Problem roku 2038', 'Technologia', '19 stycznia 2038 roku starsze systemy mogą się pomylić w liczeniu czasu.', 'Wiele systemów liczy czas jako sekundy od 1 stycznia 1970 roku. W 32-bitowej liczbie tego dnia zabraknie miejsca i wartość przeskoczy na ujemną.

Nowe systemy używają już 64 bitów, ale stare urządzenia wciąż trzeba wymienić lub zaktualizować.', 'Dokumentacja jądra Linux, „Year 2038”', null, '{"question": "Od jakiej daty liczy się czas w takich systemach?", "options": ["Od 1 stycznia 2000", "Od 1 stycznia 1970", "Od 1 stycznia 1900"], "correctIndex": 1}'::jsonb, 'published'),
  ('fact-148', 'Lampa Łukasiewicza', 'Technologia', 'Ignacy Łukasiewicz skonstruował w 1853 roku lampę naftową.', 'Lwowski aptekarz nauczył się destylować naftę z ropy naftowej, a z blacharzem Adamem Bratkowskim zbudował lampę.

W 1854 roku założył w Bóbrce jedną z pierwszych kopalń ropy na świecie, działającą do dziś jako muzeum.', 'Encyclopaedia Britannica, hasło „Ignacy Łukasiewicz”', null, '{"question": "Gdzie Łukasiewicz założył kopalnię ropy?", "options": ["W Gdańsku", "W Zakopanem", "W Bóbrce"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-149', 'Me at the zoo', 'Technologia', 'Pierwszy film na YouTube trwa 19 sekund i pokazuje słonie w zoo.', 'Wrzucił go 23 kwietnia 2005 roku współzałożyciel serwisu Jawed Karim. W nagraniu stoi przed wybiegiem dla słoni i mówi, że mają bardzo długie trąby.

Film wciąż jest dostępny i ma setki milionów wyświetleń.', 'Encyclopaedia Britannica, hasło „YouTube”', null, '{"question": "Jakie zwierzęta pokazuje pierwszy film na YouTube?", "options": ["Pandy", "Pingwiny", "Słonie"], "correctIndex": 2}'::jsonb, 'published'),
  ('fact-150', 'Zanim było Google', 'Technologia', 'Wyszukiwarka Google nazywała się początkowo BackRub.', 'Larry Page i Sergey Brin rozwijali ją na Uniwersytecie Stanforda. Nazwa odnosiła się do analizy linków prowadzących do strony.

Nową nazwę zaczerpnęli od „googola”, czyli liczby złożonej z jedynki i stu zer.', 'Encyclopaedia Britannica, hasło „Google”', null, '{"question": "Co oznacza googol?", "options": ["Największą liczbę pierwszą", "Tysiąc bajtów", "Jedynkę i sto zer"], "correctIndex": 2}'::jsonb, 'published')
on conflict (id) do nothing;
