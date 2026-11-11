# Izvori podataka u mapi `data/`

Svi slojevi preuzeti su **10. 11. 2026.** skriptom `alati/dohvati_podatke.rb` i spremljeni kao GeoJSON u WGS84 (EPSG:4326) koordinatama. Svaka datoteka u polju `metadata` nosi isti opis izvora, datum preuzimanja i licencu.

Područje prikaza: Splitsko-dalmatinska županija i okolica (zemljopisna dužina 15,4–18,0° I, širina 42,3–43,95° S), osim gdje je drukčije navedeno.

| Datoteka | Sadržaj | Broj objekata | Izvor | Licenca |
|---|---|---|---|---|
| `plaze.geojson` | Kakvoća mora za kupanje: godišnja ocjena 2026. i konačna ocjena 2023.–2026. za Splitsko-dalmatinsku, Šibensko-kninsku i Dubrovačko-neretvansku županiju | 389 | Institut za oceanografiju i ribarstvo (IOR) – [vrtlac.izor.hr/kakvoca](https://vrtlac.izor.hr/kakvoca/), skup na [data.gov.hr](https://data.gov.hr/ckan/dataset/kakvoca-mora-u-republici-hrvatskoj-konacna-hr) | Na data.gov.hr licenca nije navedena; javni podaci, uz navođenje izvora |
| `infrastruktura.geojson` | Registar odobalne infrastrukture: elektroenergetski i elektroničko-komunikacijski kabeli, plinovodi, vodovodi, podmorski ispusti (sloj „Ovdje ne sidri”) | 106 (od 345 u cijelom registru) | Hrvatski hidrografski institut (HHI) – WFS servisi `Kl_*_WEB_WFS`, katalog [registri.nipp.hr](https://registri.nipp.hr/) | Bez ograničenja uz navođenje izvora |
| `ocean.geojson` | Oceanografske mjerne postaje – temperatura i slanost mora, sezona kupanja 2024. (prosjek, minimum i maksimum izračunati iz pojedinačnih mjerenja) | 370 (od 1090) | IOR, INSPIRE usluga NIPP-a – skup na [data.gov.hr](https://data.gov.hr/ckan/dataset/oceanografske-mjerne-postaje-slanost-i-temperatura-mora-2024-inspire) | Otvorena dozvola Republike Hrvatske |
| `svjetionici.geojson` | Registar objekata sigurnosti plovidbe: svjetionici, obalna i lučka svjetla, oznake, plutače (samo status „Aktivan”) | 512 (od 1268) | Plovput d.o.o. – skup na [data.gov.hr](https://data.gov.hr/ckan/dataset/registar-objekata-sigurnosti-plovidbe) | Otvorena dozvola (OD) |
| `luke.geojson` | Lučke kapetanije i ispostave (aktivne, cijela obala) s adresom i kontaktom | 77 | HHI, javni ArcGIS servis [Lučke kapetanije i ispostave](https://services8.arcgis.com/tDYJmhP975urQUZt/arcgis/rest/services/Lu%C4%8Dke_kapetanije_i_ispostave/FeatureServer) | Licenca nije izričito navedena na servisu; javni servis HHI-ja, uz navođenje izvora |
| `eea_kupanje.geojson` | Kakvoća vode za kupanje prema Direktivi 2006/7/EZ, sezona 2025. (zadnja objavljena), s ocjenama prethodnih godina; samo hrvatske lokacije u području prikaza | 361 | Europska agencija za okoliš (EEA), servis `BathingWater_Dyna_WM_2025`; podatke dostavljaju tijela država članica – [EEA Datahub](https://www.eea.europa.eu/en/datahub/datahubitem-view/c3858959-90da-4c1f-b1a1-3c0f4a3eb2b6) | EEA – ponovna uporaba dopuštena uz navođenje izvora (CC BY 4.0) |
| `morska_podrucja.geojson` | Morska područja Jadranskog mora: nazivi kanala, zaljeva i uvala. Točka je težište područja izračunato iz granice; cijele granice nisu spremljene radi brzine karte | 57 (od 158) | HHI – WFS `morska_podrucja_v2_WFS` | Bez ograničenja uz navođenje izvora |
| `vts.geojson` | VTS sektori nadzora i upravljanja pomorskim prometom, s pozivnim znakom i VHF kanalom. Granice pojednostavljene (odstupanje do oko 300 m) | 10 (od 15) | HHI – WFS `VTS_WFS` | Bez ograničenja uz navođenje izvora |
| `mreza_more.json` | Mreža točaka za kartu temperature mora (same koordinate, bez mjerenja): pravilna mreža 0,15° × 0,1°, zadržane točke na moru | 39 (od 70) | Izračunato; provjera mora preko Open-Meteo Elevation i Marine API-ja | CC BY 4.0 |
| `lucke_uprave.json` | Popis lučkih uprava (naziv, adresa, web, kontakt). Skup nema koordinate, pa nije na karti | 28 | Ministarstvo mora, prometa i infrastrukture – skup na [data.gov.hr](https://data.gov.hr/ckan/dataset/https-mmpi-gov-hr-userdocsimages-dokumenti-more-more-5_26-lucke-uprave-25-5_26-1-xlsx) | Otvorena dozvola (OD) |

## Podaci koji se dohvaćaju uživo (nisu u mapi `data/`)

- **Prognoza vjetra, valova, temperature mora i zraka te UV indeksa:** [Open-Meteo](https://open-meteo.com/) (Forecast i Marine API), licenca CC BY 4.0.
- **Podloga karte:** © suradnici [OpenStreetMapa](https://www.openstreetmap.org/copyright) (ODbL); pomorske oznake © [OpenSeaMap](https://www.openseamap.org/) (CC BY-SA).

## Što je demo

- **Sidrišta (8 točaka):** lokacije su približne, a smjer izloženosti uvale je procjena tima. Nisu službeni podatak. Službeni popis koncesioniranih sidrišta s koordinatama nismo pronašli kao otvoreni skup (stranica gov.hr/hr/nautika/1558 nema popis ni datoteku, provjereno 10. 11. 2026.).

Datoteka `podaci.js` sadrži iste slojeve spakirane u jednu datoteku, da karta radi i kad se `index.html` otvori dvoklikom.

## Napomene o obradi

- Ništa nije izmišljeno ni ručno upisano: objekti bez koordinata su izostavljeni.
- Ocjene kakvoće mora dolaze kao riječi (izvrsno, dobro, zadovoljavajuće, nezadovoljavajuće), prema Uredbi o kakvoći mora za kupanje (NN 73/08). Stari WFS sloj `plaze:plaze_spat` (polje `KAKVOCA` s brojevima) nije korišten jer ima samo 49 zapisa; usporedbom s CSV-om svih 31 podudarnih točaka s `KAKVOCA = 1` ima ocjenu „izvrsno”, što potvrđuje da je 1 najbolja ocjena.
- Koordinate infrastrukture zaokružene su na 5 decimala (oko 1 m) radi manje datoteke.
- Naftovoda iz registra nema u području prikaza (oba su kod otoka Krka).
