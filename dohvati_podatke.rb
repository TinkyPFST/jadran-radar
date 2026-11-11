#!/usr/bin/env ruby
# Jadran radar – dohvat stvarnih otvorenih podataka u mapu data/ (GeoJSON, WGS84).
# Pokretanje (macOS ima Ruby ugrađen, ne treba ništa instalirati):
#   ruby alati/dohvati_podatke.rb
# Sirove preuzete datoteke spremaju se u privremenu mapu, a u data/ idu samo
# očišćeni slojevi. Ništa se ne izmišlja: objekti bez koordinata se preskaču.
require 'json'
require 'csv'
require 'tmpdir'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
DATA = File.join(ROOT, 'data')
RAW  = ENV['RAW_DIR'] || Dir.mktmpdir('jadran-radar')
FileUtils.mkdir_p([DATA, RAW])
DANAS = Time.now.strftime('%Y-%m-%d')

# Područje prikaza: Splitsko-dalmatinska županija i okolica (Šibenik – Pelješac, do Palagruže).
BBOX = { w: 15.4, e: 18.0, s: 42.3, n: 43.95 }.freeze
def u_podrucju?(lon, lat)
  lon.between?(BBOX[:w], BBOX[:e]) && lat.between?(BBOX[:s], BBOX[:n])
end

def preuzmi(url, ime)
  put = File.join(RAW, ime)
  unless File.size?(put)
    ok = system('curl', '-sL', '-m', '180', '--fail', url, '-o', put)
    raise "Preuzimanje nije uspjelo: #{url}" unless ok && File.size?(put)
  end
  File.read(put, encoding: 'utf-8')
end

def spremi(ime, features, meta)
  gj = { type: 'FeatureCollection', metadata: meta.merge(preuzeto: DANAS, broj_objekata: features.size), features: features }
  File.write(File.join(DATA, ime), JSON.generate(gj))
  puts format('%-28s %5d objekata  %7.1f kB', ime, features.size, File.size(File.join(DATA, ime)) / 1024.0)
end

def tocka(lon, lat, props)
  { type: 'Feature', geometry: { type: 'Point', coordinates: [lon.round(6), lat.round(6)] }, properties: props }
end

izvjesce = []

# 1) IOR – kakvoća mora za kupanje (CSV po županijama, koordinate već u WGS84)
begin
  zup = { 2 => 'Splitsko-dalmatinska', 3 => 'Šibensko-kninska', 1 => 'Dubrovačko-neretvanska' }
  god = 2026
  f = []
  zup.each do |id, naziv|
    url = "https://vrtlac.izor.hr/ords/kakvoca/daj_csv?p_god=#{god}&p_zup_id=#{id}"
    red = CSV.parse(preuzmi(url, "ior_#{god}_#{id}.csv").sub(/\A﻿/, ''), col_sep: ';', liberal_parsing: true)
    red.drop(1).each do |r|
      lat = Float(r[1]) rescue next
      lon = Float(r[2]) rescue next
      next unless lat.between?(42, 46) && lon.between?(13, 19)
      f << tocka(lon, lat, naziv: r[0].to_s.strip, mjesto: r[3].to_s.strip, podrucje: r[4].to_s.strip, zupanija: naziv,
                           ocjena: r[5].to_s.strip, konacna: r[7].to_s.strip, sezona: god, razdoblje: "#{god - 3}–#{god}")
    end
  end
  spremi('plaze.geojson', f,
         naziv: 'Kakvoća mora za kupanje', izvor: 'Institut za oceanografiju i ribarstvo (IOR), Split',
         url: 'https://vrtlac.izor.hr/kakvoca/', portal: 'https://data.gov.hr/ckan/dataset/kakvoca-mora-u-republici-hrvatskoj-konacna-hr',
         licenca: 'Na data.gov.hr licenca nije navedena; javni podaci, uz navođenje izvora',
         napomena: "Godišnja ocjena #{god}. i konačna ocjena #{god - 3}–#{god}. prema Uredbi o kakvoći mora za kupanje (NN 73/08)")
  izvjesce << "plaze: #{f.size}"
rescue => e
  warn "PLAŽE – nije uspjelo: #{e.message}"
end

# 2) HHI – Registar odobalne infrastrukture (WFS, GeoJSON u EPSG:4326)
begin
  slojevi = {
    'Kl_1101_EE' => 'Elektroenergetski kabel', 'Kl_2103_EK' => 'Elektroničko-komunikacijski kabel',
    'Kl_4101_PL' => 'Plinovod', 'Kl_4104_PL' => 'Plinska platforma / objekt', 'Kl_5101_NF' => 'Naftovod',
    'Kl_6101_VC' => 'Vodovod', 'Kl_7101_OD' => 'Odvodnja (podmorski ispust)'
  }
  f = []
  ukupno = 0
  slojevi.each do |sl, vrsta|
    url = "https://dservices8.arcgis.com/tDYJmhP975urQUZt/arcgis/services/#{sl}_WEB_WFS/WFSServer" \
          "?service=WFS&version=2.0.0&request=GetFeature&typeNames=#{sl}_WEB_WFS:#{sl}&outputFormat=GEOJSON&srsName=EPSG:4326"
    gj = JSON.parse(preuzmi(url, "hhi_#{sl}.json"))
    ukupno += gj['features'].size
    gj['features'].each do |x|
      g = x['geometry'] or next
      zaokruzi = lambda do |c|
        if c[0].is_a?(Numeric) then [c[0].round(5), c[1].round(5)]
        else
          r = c.map { |i| zaokruzi.call(i) }
          r[0].is_a?(Array) && r[0][0].is_a?(Numeric) ? r.chunk_while { |a, b| a == b }.map(&:first) : r
        end
      end
      koord = zaokruzi.call(g['coordinates'])
      ravno = koord.flatten.each_slice(2)
      next unless ravno.any? { |lon, lat| u_podrucju?(lon, lat) }
      p = x['properties']
      f << { type: 'Feature', geometry: { type: g['type'], coordinates: koord },
             properties: { vrsta: vrsta, naziv: p['Naziv'].to_s.strip, oznaka: p['upr_obj_id'], izmjera: p['dat_izvor'], azurirano: p['datupd'] } }
    end
  end
  spremi('infrastruktura.geojson', f,
         naziv: 'Registar odobalne infrastrukture', izvor: 'Hrvatski hidrografski institut (HHI)',
         url: 'https://registri.nipp.hr/', licenca: 'Bez ograničenja uz navođenje izvora',
         napomena: "Od #{ukupno} objekata u registru zadržani su oni u području prikaza. Koordinate zaokružene na 5 decimala (~1 m).")
  izvjesce << "infrastruktura: #{f.size}/#{ukupno}"
rescue => e
  warn "INFRASTRUKTURA – nije uspjelo: #{e.message}"
end

# 3) IOR – oceanografske mjerne postaje, temperatura i slanost mora 2024 (INSPIRE WFS)
begin
  oc = 'https://transformiraj.nipp.hr/ows/services/org.15.e63eb78a-c05a-4ea4-8ffc-8afa912e4454_wfs?SERVICE=WFS&VERSION=2.0.0&REQUEST=GetFeature'
  post = JSON.parse(preuzmi("#{oc}&TYPENAMES=ef:EnvironmentalMonitoringFacility&OUTPUTFORMAT=application%2Fgeo%2Bjson&SRSNAME=EPSG:4326", 'oc_postaje.json'))
  gml = preuzmi("#{oc}&TYPENAMES=omso:PointObservation", 'oc_mjerenja.gml')
  mj = {}
  gml.scan(/<omso:PointObservation gml:id="([^"]+)">(.*?)<\/omso:PointObservation>/m) do |id, tijelo|
    v = tijelo[/<swe:values>(.*?)<\/swe:values>/m, 1] or next
    redovi = v.split(/\s+/).reject(&:empty?).map { |r| r.split(',') }.select { |r| r.size >= 3 }
    mj[id] = redovi.map { |t, temp, sal| [t, (Float(temp) rescue nil), (Float(sal) rescue nil)] }
  end
  f = []
  post['features'].each do |x|
    c = x['geometry'] && x['geometry']['coordinates'].flatten.first(2) or next
    next unless u_podrucju?(c[0], c[1])
    id = x.dig('properties', 'hasObservation', 'href').to_s.sub('#', '')
    m = mj[id] or next
    t = m.map { |r| r[1] }.compact
    s = m.map { |r| r[2] }.compact
    next if t.empty? && s.empty?
    sr = ->(a) { a.empty? ? nil : (a.sum / a.size).round(1) }
    f << tocka(c[0], c[1], naziv: x.dig('properties', 'name').to_s.strip, mjerenja: m.size,
                           od: m.first[0][0, 10], do: m.last[0][0, 10],
                           temp_sr: sr.(t), temp_min: t.min, temp_max: t.max, slanost_sr: sr.(s))
  end
  spremi('ocean.geojson', f,
         naziv: 'Oceanografske mjerne postaje – slanost i temperatura mora 2024', izvor: 'Institut za oceanografiju i ribarstvo (IOR), INSPIRE usluga NIPP-a',
         url: 'https://data.gov.hr/ckan/dataset/oceanografske-mjerne-postaje-slanost-i-temperatura-mora-2024-inspire',
         licenca: 'Otvorena dozvola Republike Hrvatske',
         napomena: 'Prosjek, minimum i maksimum izračunati su iz pojedinačnih mjerenja u sezoni kupanja 2024. (temperatura u °C, slanost u PSU).')
  izvjesce << "ocean: #{f.size}/#{post['features'].size}"
rescue => e
  warn "OCEAN – nije uspjelo: #{e.message}"
end

# 4a) Plovput – Registar objekata sigurnosti plovidbe (WFS)
begin
  url = 'https://rosp.plovput.hr/plovput_ows/ows?service=WFS&version=1.0.0&request=GetFeature&typeName=plovput_ows:RospObjekti&outputFormat=application/json&srsName=EPSG:4326'
  gj = JSON.parse(preuzmi(url, 'rosp.json'))
  f = []
  gj['features'].each do |x|
    c = x['geometry'] && x['geometry']['coordinates'] or next
    p = x['properties']
    next unless p['status_objekta'] == 'Aktivan' && u_podrucju?(c[0], c[1])
    cisto = ->(v) { v.to_s.strip.empty? ? nil : v.to_s.strip }
    f << tocka(c[0], c[1], { naziv: cisto.(p['naziv_objekta']), opis: cisto.(p['opis_objekta']), svjetlo: cisto.(p['kar_svjetla']),
                             domet_nm: cisto.(p['domet_svjetla']), visina_m: p['visina_srm'], plutaca: cisto.(p['boja_plutace']),
                             kapetanija: cisto.(p['lucka_kapetanija']), tip: p['tip_objekta'], popis_svjetala: cisto.(p['ps_br']) }.compact)
  end
  spremi('svjetionici.geojson', f,
         naziv: 'Registar objekata sigurnosti plovidbe', izvor: 'Plovput d.o.o.',
         url: 'https://data.gov.hr/ckan/dataset/registar-objekata-sigurnosti-plovidbe', licenca: 'Otvorena dozvola (OD)',
         napomena: "Samo objekti sa statusom Aktivan u području prikaza (od #{gj['features'].size} u cijelom registru).")
  izvjesce << "svjetionici: #{f.size}/#{gj['features'].size}"
rescue => e
  warn "OBJEKTI SIGURNOSTI PLOVIDBE – nije uspjelo: #{e.message}"
end

# 4b) HHI – lučke kapetanije i ispostave (stvarne lokacije)
begin
  url = 'https://services8.arcgis.com/tDYJmhP975urQUZt/arcgis/rest/services/Lu%C4%8Dke_kapetanije_i_ispostave/FeatureServer/0/query?where=1%3D1&outFields=*&f=geojson'
  gj = JSON.parse(preuzmi(url, 'lk.json'))
  f = []
  gj['features'].each do |x|
    c = x['geometry'] && x['geometry']['coordinates'] or next
    p = x['properties']
    next unless p['Aktivno'].to_s.strip == 'Da'
    cisto = ->(v) { s = v.to_s.strip; s.empty? || s == '-' ? nil : s }
    f << tocka(c[0], c[1], { naziv: cisto.(p['Naziv']), vrsta: cisto.(p['Vrsta']), kapetanija: cisto.(p['LK']),
                             adresa: cisto.(p['Adresa']), telefon: cisto.(p['Telefon']), email: cisto.(p['Email']) }.compact)
  end
  spremi('luke.geojson', f,
         naziv: 'Lučke kapetanije i ispostave', izvor: 'Hrvatski hidrografski institut (HHI), javni ArcGIS servis',
         url: 'https://services8.arcgis.com/tDYJmhP975urQUZt/arcgis/rest/services/Lu%C4%8Dke_kapetanije_i_ispostave/FeatureServer',
         licenca: 'Licenca nije izričito navedena na servisu; javni servis HHI-ja, uz navođenje izvora',
         napomena: 'Samo aktivne kapetanije i ispostave, cijela obala.')
  izvjesce << "luke: #{f.size}"
rescue => e
  warn "LUČKE KAPETANIJE – nije uspjelo: #{e.message}"
end

# 4c) MMPI – Lučke uprave (CSV bez koordinata -> popis, ne ide na kartu)
begin
  url = 'https://data.gov.hr/ckan/dataset/f8ab9ddb-db0d-4dff-8867-be48f29c8f83/resource/b6605f42-6f91-4521-853a-d27d8771c368/download/lucke-uprave-25-5_261.csv'
  red = CSV.parse(preuzmi(url, 'lucke_uprave.csv').sub(/\A﻿/, ''), col_sep: ';', liberal_parsing: true)
  cisto = ->(v) { v.to_s.gsub(/\s+/, ' ').strip }
  popis = red.select { |r| r[2].to_s =~ /uprava/i && r[3].to_s =~ /\d{5}|\d{2} \d{3}/ }
             .map { |r| { vrsta: cisto.(r[1]), naziv: cisto.(r[2]), adresa: cisto.(r[3]), web: cisto.(r[4]), telefon: cisto.(r[6]), email: cisto.(r[7]) } }
  File.write(File.join(DATA, 'lucke_uprave.json'), JSON.generate(
    metadata: { naziv: 'Lučke uprave', izvor: 'Ministarstvo mora, prometa i infrastrukture', licenca: 'Otvorena dozvola (OD)', preuzeto: DANAS,
                url: 'https://data.gov.hr/ckan/dataset/https-mmpi-gov-hr-userdocsimages-dokumenti-more-more-5_26-lucke-uprave-25-5_26-1-xlsx',
                napomena: 'Skup nema koordinate, pa se prikazuje kao popis, a ne na karti.' },
    uprave: popis))
  puts format('%-28s %5d zapisa', 'lucke_uprave.json', popis.size)
  izvjesce << "lucke_uprave: #{popis.size}"
rescue => e
  warn "LUČKE UPRAVE – nije uspjelo: #{e.message}"
end

# 5) EEA – kakvoća vode za kupanje prema EU direktivi 2006/7/EZ (sezona 2025.)
begin
  god = 2025
  url = "https://water.discomap.eea.europa.eu/arcgis/rest/services/BathingWater/BathingWater_Dyna_WM_#{god}/MapServer/3/query" \
        "?where=countryCode%3D%27HR%27&outFields=*&geometry=#{BBOX[:w]},#{BBOX[:s]},#{BBOX[:e]},#{BBOX[:n]}" \
        '&geometryType=esriGeometryEnvelope&inSR=4326&outSR=4326&f=geojson'
  gj = JSON.parse(preuzmi(url, 'eea.json'))
  raise 'odgovor je odrezan (previše zapisa)' if gj['exceededTransferLimit']
  hr = { 'Excellent' => 'izvrsno', 'Good' => 'dobro', 'Sufficient' => 'zadovoljavajuće', 'Poor' => 'nezadovoljavajuće', 'Not classified' => 'nije razvrstano' }
  f = []
  gj['features'].each do |x|
    c = x['geometry'] && x['geometry']['coordinates'] or next
    p = x['properties']
    next unless p['countryCode'] == 'HR'
    proslo = (1..4).map { |i| [god - i, hr[p["qualityStatus_minus#{i}"]]] }.select { |_, v| v }.map { |g, v| "#{g}: #{v}" }.join(', ')
    f << tocka(c[0], c[1], { naziv: p['bathingWaterName'].to_s.strip, ocjena: hr[p['qualityStatus']] || p['qualityStatus'], sezona: god,
                             ranije: (proslo.empty? ? nil : proslo), oznaka: p['bathingWaterIdentifier'], vrsta_vode: p['bwWaterCategory'] }.compact)
  end
  spremi('eea_kupanje.geojson', f,
         naziv: "Kakvoća vode za kupanje u EU, sezona #{god}.", izvor: 'Europska agencija za okoliš (EEA); podatke dostavljaju tijela država članica',
         url: 'https://www.eea.europa.eu/en/datahub/datahubitem-view/c3858959-90da-4c1f-b1a1-3c0f4a3eb2b6',
         licenca: 'EEA – ponovna uporaba dopuštena uz navođenje izvora (CC BY 4.0)',
         napomena: "Ocjene prema Direktivi 2006/7/EZ za sezonu #{god}. (zadnja objavljena), samo hrvatske lokacije u području prikaza.")
  izvjesce << "eea: #{f.size}"
rescue => e
  warn "EEA – nije uspjelo: #{e.message}"
end

# Pomoćno: Douglas–Peucker pojednostavljenje crte (tolerancija u stupnjevima)
def pojednostavi(t, tol)
  return t if t.size < 4
  zadrzi = Array.new(t.size, false)
  zadrzi[0] = zadrzi[-1] = true
  stog = [[0, t.size - 1]]
  until stog.empty?
    a, b = stog.pop
    next if b <= a + 1
    ax, ay = t[a]; bx, by = t[b]
    dx = bx - ax; dy = by - ay; d2 = dx * dx + dy * dy
    naj = 0; idx = nil
    (a + 1...b).each do |i|
      px, py = t[i]
      u = d2.zero? ? 0 : (((px - ax) * dx + (py - ay) * dy) / d2).clamp(0, 1)
      d = Math.hypot(px - (ax + u * dx), py - (ay + u * dy))
      (naj = d; idx = i) if d > naj
    end
    next unless idx && naj > tol
    zadrzi[idx] = true
    stog << [a, idx] << [idx, b]
  end
  t.each_index.select { |i| zadrzi[i] }.map { |i| [t[i][0].round(4), t[i][1].round(4)] }
end

HHI_WFS = 'https://dservices8.arcgis.com/tDYJmhP975urQUZt/arcgis/services/%s/WFSServer?service=WFS&version=2.0.0&request=GetFeature&typeNames=%s&outputFormat=GEOJSON&srsName=EPSG:4326'

# 6) HHI – morska područja Jadranskog mora (nazivi kanala, zaljeva, uvala) -> natpisi u težištu poligona
begin
  gj = JSON.parse(preuzmi(format(HHI_WFS, 'morska_podrucja_v2_WFS', 'morska_podrucja_v2_WFS:morska_podrucja_v2'), 'hhi_morska.json'))
  f = []
  gj['features'].each do |x|
    g = x['geometry'] or next
    polis = g['type'] == 'Polygon' ? [g['coordinates']] : g['coordinates']
    prsten = polis.map(&:first).max_by(&:size)
    pov = cx = cy = 0.0
    prsten.each_cons(2) { |(x1, y1), (x2, y2)| k = x1 * y2 - x2 * y1; pov += k; cx += (x1 + x2) * k; cy += (y1 + y2) * k }
    next if pov.zero?
    lon = cx / (3 * pov); lat = cy / (3 * pov)
    next unless u_podrucju?(lon, lat)
    p = x['properties']
    f << tocka(lon, lat, naziv: p['Naziv'].to_s.strip, podjela: p['podjela'].to_s.strip)
  end
  spremi('morska_podrucja.geojson', f,
         naziv: 'Morska područja Jadranskog mora', izvor: 'Hrvatski hidrografski institut (HHI)', url: 'https://registri.nipp.hr/',
         licenca: 'Bez ograničenja uz navođenje izvora',
         napomena: "Od #{gj['features'].size} područja zadržana su ona u području prikaza. Radi brzine karte prikazuje se naziv u težištu područja, a ne cijela granica.")
  izvjesce << "morska_podrucja: #{f.size}/#{gj['features'].size}"
rescue => e
  warn "MORSKA PODRUČJA – nije uspjelo: #{e.message}"
end

# 7) HHI – VTS (služba nadzora i upravljanja pomorskim prometom), sektori
begin
  gj = JSON.parse(preuzmi(format(HHI_WFS, 'VTS_WFS', 'VTS_WFS:VTS_shp'), 'hhi_vts.json'))
  f = []
  gj['features'].each do |x|
    g = x['geometry'] or next
    polis = g['type'] == 'Polygon' ? [g['coordinates']] : g['coordinates']
    next unless polis.any? { |po| po[0].any? { |lon, lat| u_podrucju?(lon, lat) } }
    koord = polis.map { |po| po.map { |pr| pojednostavi(pr, 0.003) }.select { |pr| pr.size >= 4 } }.reject(&:empty?)
    p = x['properties']
    cisto = ->(v) { s = v.to_s.strip; s.empty? ? nil : s }
    f << { type: 'Feature', geometry: { type: 'MultiPolygon', coordinates: koord },
           properties: { naziv: cisto.(p['NAME']), vrsta: cisto.(p['Vrsta']), pozivni: cisto.(p['Pozivni']), vhf: cisto.(p['VHS_gl']), vhf_pom: cisto.(p['VHS_pom']) }.compact }
  end
  spremi('vts.geojson', f,
         naziv: 'VTS – sektori nadzora pomorskog prometa', izvor: 'Hrvatski hidrografski institut (HHI)', url: 'https://registri.nipp.hr/',
         licenca: 'Bez ograničenja uz navođenje izvora',
         napomena: 'Sektori koji zahvaćaju područje prikaza. Granice su pojednostavljene (odstupanje do oko 300 m) radi brzine karte.')
  izvjesce << "vts: #{f.size}/#{gj['features'].size}"
rescue => e
  warn "VTS – nije uspjelo: #{e.message}"
end

# 8) Mreža točaka na moru za kartu temperature mora (same točke; temperatura se dohvaća uživo s Open-Meteo)
begin
  kand = []
  lat = 42.95
  while lat <= 43.62
    lon = 15.95
    while lon <= 17.36
      kand << [lat.round(3), lon.round(3)]
      lon += 0.15
    end
    lat += 0.1
  end
  q = "latitude=#{kand.map(&:first).join(',')}&longitude=#{kand.map(&:last).join(',')}"
  visina = JSON.parse(preuzmi("https://api.open-meteo.com/v1/elevation?#{q}", 'mreza_visina.json'))['elevation']
  more = [JSON.parse(preuzmi("https://marine-api.open-meteo.com/v1/marine?#{q}&current=sea_surface_temperature", 'mreza_more.json'))].flatten
  tocke = kand.each_index.select { |i| visina[i].to_f <= 0 && more[i].dig('current', 'sea_surface_temperature') }.map { |i| kand[i] }
  File.write(File.join(DATA, 'mreza_more.json'), JSON.generate(
    metadata: { naziv: 'Mreža točaka za temperaturu mora', izvor: 'Open-Meteo (Marine API i Elevation API)', licenca: 'CC BY 4.0', preuzeto: DANAS,
                napomena: "Pravilna mreža (0,15° × 0,1°) uz obalu Splitsko-dalmatinske županije. Od #{kand.size} točaka zadržane su one na moru: nadmorska visina 0 m i dostupna temperatura mora." },
    tocke: tocke))
  puts format('%-28s %5d točaka (od %d)', 'mreza_more.json', tocke.size, kand.size)
  izvjesce << "mreza_more: #{tocke.size}/#{kand.size}"
rescue => e
  warn "MREŽA MORA – nije uspjelo: #{e.message}"
end

# 9) Sve slojeve spakirati i u data/podaci.js, da karta radi i kad se index.html otvori dvoklikom (bez poslužitelja)
begin
  kljucevi = { pla: 'plaze.geojson', inf: 'infrastruktura.geojson', ocean: 'ocean.geojson', svj: 'svjetionici.geojson', luke: 'luke.geojson',
               eea: 'eea_kupanje.geojson', mp: 'morska_podrucja.geojson', vts: 'vts.geojson', uprave: 'lucke_uprave.json', mreza: 'mreza_more.json' }
  dijelovi = kljucevi.map { |k, ime| put = File.join(DATA, ime); File.exist?(put) ? "#{k}:#{File.read(put, encoding: 'utf-8')}" : nil }.compact
  File.write(File.join(DATA, 'podaci.js'), "// Automatski izrađeno skriptom alati/dohvati_podatke.rb (#{DANAS}). Isti podaci kao u datotekama .geojson u ovoj mapi.\nwindow.JR_DATA={#{dijelovi.join(",\n")}};\n")
  puts format('%-28s %5d slojeva  %7.1f kB', 'podaci.js', dijelovi.size, File.size(File.join(DATA, 'podaci.js')) / 1024.0)
rescue => e
  warn "PODACI.JS – nije uspjelo: #{e.message}"
end

puts "Gotovo (#{DANAS}): #{izvjesce.join(', ')}"
