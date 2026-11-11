# Jadran radar

**Karta mora za nautičare i kupače, izrađena na otvorenim podacima Republike Hrvatske.**

Projekt za Datathon Portala otvorenih podataka ([data.gov.hr](https://data.gov.hr)), izazov **Okoliš i održivi prostor**.

- Aplikacija: <https://tinkypfst.github.io/jadran-radar/>
- Kod: <https://github.com/TinkyPFST/jadran-radar>
- Video: .
- Tim: Kapetani (Tin Peric i Niki Krsticevic)

## Problem

Podaci o moru postoje i javni su, ali su razasuti po desetak servisa različitih ustanova i u oblicima koje običan korisnik ne može otvoriti (WFS, GML, INSPIRE). Zato se u praksi događa ovo:

- Nautičar ne zna da baca sidro iznad podmorskog kabela, vodovoda ili ispusta. Sidrenje tamo je zabranjeno, oštećuje infrastrukturu i morsko dno.
- Uvala koja je ujutro mirna poslijepodne može biti potpuno izložena vjetru, a to se iz obične prognoze ne vidi na prvi pogled.
- Kupač ne zna kakva je službena kakvoća mora na plaži na koju ide, iako se ona mjeri svakih petnaestak dana.

## Rješenje

Jadran radar sve to stavlja na jednu kartu srednjeg Jadrana (Splitsko-dalmatinska županija i okolica) i povezuje s prognozom za idućih 48 sati. Ima dva načina rada.

**Nautičar**

- **Ovdje ne sidri:** 106 podmorskih kabela, cjevovoda i ispusta iz Registra odobalne infrastrukture.
- **Sidrišta:** boja pokazuje je li uvala zaštićena od vjetra u odabranom satu (zeleno zaštićeno, žuto oprez, crveno izloženo).
- **Najbliže sigurno sidrište:** jednim gumbom do najbližeg sidrišta koje je u tom satu zaštićeno.
- **Svjetla i plutače:** 512 objekata sigurnosti plovidbe s karakteristikom svjetla i dometom.
- **Strelice vjetra:** na svakom sidrištu strelica pokazuje kamo vjetar puše i koliko čvorova.
- **Upozorenje na buru i jugo:** crvena traka na vrhu ako u idućih 48 sati bura (SI) ili jugo (JI) prelaze 25 čvorova na nekom sidrištu, s vremenom početka.
- **Kapetanije i ispostave:** adresa, telefon i e-pošta.
- **Nazivi morskih područja:** kanali, zaljevi i uvale prema HHI-ju (57 naziva).
- **VTS sektori:** 10 sektora nadzora pomorskog prometa s pozivnim znakom i VHF kanalom.

**Kupač**

- **Kakvoća mora:** službena ocjena za 389 plaža (izvrsno, dobro, zadovoljavajuće, nezadovoljavajuće).
- **Uvjeti za kupanje:** prognoza valova, vjetra, temperature mora i zraka te UV indeksa za odabrani sat.
- **Karta temperature mora:** 39 točaka na moru uz obalu Splitsko-dalmatinske županije, obojenih od plave (10 °C) do crvene (28 °C). Prati klizač sati.
- **EU ocjena vode za kupanje:** 361 lokacija iz podataka Europske agencije za okoliš za sezonu 2025.
- **Temperatura i slanost:** stvarna mjerenja iz sezone 2024. na 370 postaja.

## Kako koristiti

1. Otvori aplikaciju i klikni **Kreni**.
2. Gore odaberi **Nautičar** ili **Kupač**.
3. Klizačem **Prognoza za** odaberi sat (od sada do 47 sati unaprijed). Boje sidrišta i uvjeti na plažama mijenjaju se s prognozom.
4. Klikni bilo koju točku ili crtu na karti za detalje. Na dnu svakog okvira piše izvor podatka i datum preuzimanja.
5. U panelu **Slojevi i legenda** uključi ili isključi slojeve. Manja svjetla i plutače vide se kad približiš kartu.
6. Gumb **Izvori podataka** otvara popis svih skupova s licencama i linkovima.

## Izvori podataka i licence

Svi slojevi preuzeti su 10. 11. 2026. Potpuni opis je u [data/IZVORI.md](data/IZVORI.md).

| Sloj | Izvor | Objekata | Licenca |
|---|---|---|---|
| Kakvoća mora za kupanje 2026. | Institut za oceanografiju i ribarstvo (IOR) – [data.gov.hr](https://data.gov.hr/ckan/dataset/kakvoca-mora-u-republici-hrvatskoj-konacna-hr) | 389 | Nije navedena na portalu; javni podaci, uz navođenje izvora |
| Registar odobalne infrastrukture | Hrvatski hidrografski institut (HHI) – [registri.nipp.hr](https://registri.nipp.hr/) | 106 | Bez ograničenja uz navođenje izvora |
| Oceanografske mjerne postaje – slanost i temperatura mora 2024. | IOR, INSPIRE usluga – [data.gov.hr](https://data.gov.hr/ckan/dataset/oceanografske-mjerne-postaje-slanost-i-temperatura-mora-2024-inspire) | 370 | Otvorena dozvola RH |
| Registar objekata sigurnosti plovidbe | Plovput d.o.o. – [data.gov.hr](https://data.gov.hr/ckan/dataset/registar-objekata-sigurnosti-plovidbe) | 512 | Otvorena dozvola |
| Lučke kapetanije i ispostave | HHI, javni ArcGIS servis | 77 | Nije izričito navedena; javni servis, uz navođenje izvora |
| Kakvoća vode za kupanje u EU, sezona 2025. | Europska agencija za okoliš (EEA) – [Bathing Water Directive](https://www.eea.europa.eu/en/datahub/datahubitem-view/c3858959-90da-4c1f-b1a1-3c0f4a3eb2b6) | 361 | Ponovna uporaba uz navođenje izvora (CC BY 4.0) |
| Morska područja Jadranskog mora (nazivi) | HHI – [registri.nipp.hr](https://registri.nipp.hr/) | 57 | Bez ograničenja uz navođenje izvora |
| VTS – sektori nadzora pomorskog prometa | HHI – [registri.nipp.hr](https://registri.nipp.hr/) | 10 | Bez ograničenja uz navođenje izvora |
| Lučke uprave (popis, bez koordinata) | Ministarstvo mora, prometa i infrastrukture – [data.gov.hr](https://data.gov.hr/ckan/dataset/https-mmpi-gov-hr-userdocsimages-dokumenti-more-more-5_26-lucke-uprave-25-5_26-1-xlsx) | 28 | Otvorena dozvola |
| Prognoza vjetra, valova, temperature mora i zraka, UV indeks (uživo) | [Open-Meteo](https://open-meteo.com/) | – | CC BY 4.0 |
| Podloga karte i pomorske oznake | [OpenStreetMap](https://www.openstreetmap.org/copyright), [OpenSeaMap](https://www.openseamap.org/) | – | ODbL, CC BY-SA |

## Što je demo

- **Sidrišta (8 točaka)** imaju približne lokacije, a smjer izloženosti svake uvale procijenio je tim. To nisu službeni podaci. Otvoreni skup s koordinatama koncesioniranih sidrišta nismo pronašli. U aplikaciji su označena oznakom **DEMO** u popupu, legendi i uvodnom okviru.
- Ocjena „zaštićeno / oprez / izloženo” jednostavno je pravilo (smjer i jačina vjetra te udari u odnosu na otvorenost uvale), a ne službena preporuka.
- Upozorenje na buru i jugo računa se iz iste prognoze: smjer vjetra 22,5–67,5° (SI) ili 112,5–157,5° (JI) i vjetar ili udari iznad 25 čvorova.
- Točke karte temperature mora su pravilna mreža; zadržane su samo točke na moru (nadmorska visina 0 m i dostupna temperatura mora). Temperatura je prognoza modela, ne mjerenje.
- Sve ostalo na karti su stvarni podaci iz navedenih izvora. Nijedna koordinata nije ručno upisana ni izmišljena.

Karta je informativna i ne zamjenjuje službene pomorske karte, oglase za pomorce ni vremenska upozorenja.

## Kako pokrenuti

Aplikacija je jedna datoteka (`index.html`) i mapa `data/`. Ne treba ništa instalirati.

**Na internetu:** otvori link aplikacije s vrha ove stranice.

**Na svom računalu:** dvoklikni `index.html`. Podaci se učitavaju iz datoteke `data/podaci.js`, pa karta radi i bez poslužitelja (za prognozu treba internet).

Tko želi, može je pokrenuti i preko lokalnog poslužitelja. U Terminalu, u mapi projekta:

```bash
ruby -run -e httpd . -p 8765
```

Zatim otvori `http://localhost:8765` u pregledniku.

**Osvježavanje podataka:** jedna naredba ponovno preuzima sve slojeve iz izvora u mapu `data/`:

```bash
ruby alati/dohvati_podatke.rb
```

## Struktura projekta

| Datoteka | Što je |
|---|---|
| `index.html` | Cijela aplikacija (karta, prognoza, izgled) |
| `data/*.geojson` | Slojevi podataka u WGS84 koordinatama |
| `data/podaci.js` | Isti slojevi spakirani u jednu datoteku koju karta učitava (izrađuje je skripta) |
| `data/IZVORI.md` | Izvor, datum preuzimanja i licenca za svaki sloj |
| `alati/dohvati_podatke.rb` | Skripta koja preuzima i čisti podatke |
| `OPIS.md` | Kratki opis projekta |
| `VIDEO_SKRIPTA.md` | Skripta za video od 2 minute |

Korištene biblioteke: [Leaflet](https://leafletjs.com/) 1.9.4 (BSD-2).

## Ideje za nastavak

- **Stvarna sidrišta:** zamijeniti demo točke službenim popisom koncesioniranih sidrišta kad bude objavljen kao otvoreni skup s koordinatama, a izloženost uvale računati iz obalne crte HHI-ja.
- **Posidonija:** dodati Kartu staništa RH kao drugi razlog „ovdje ne sidri”, jer sidra uništavaju livade morske cvjetnice.
- **Upozorenje pri sidrenju:** kad je korisnik na moru, javiti mu ako se nalazi iznad kabela ili cjevovoda.
- **Cijeli Jadran:** podaci već postoje za cijelu obalu, treba samo proširiti područje.
- **Kakvoća mora tijekom sezone:** prikazati pojedinačna mjerenja, ne samo godišnju ocjenu.
- **Rad bez interneta:** spremiti kartu i podatke na mobitel za plovidbu izvan dometa signala.
- **Engleski jezik** za strane nautičare.
