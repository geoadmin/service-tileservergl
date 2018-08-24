 # service-tileservergl

## Setting up

```bash
$ git clone --recurse-submodules git@github.com:geoadmin/service-tileservergl.git
$ cd service-tileservergl
$ make user
```

If already cloned, make sure you initialize the submodule `tileserver-gl`.

```bash
$ git submodule init && git submodule update
```

## Create a new tile tileset and update the server


### Setup tippecanoe


####  Install dependencies

```bash
$ sudo apt-get install build-essential libsqlite3-dev zlib1g-dev python-virtualenv npm docker-compose
// The current version of geoadmin/tippecanoe needs gcc 4
$ sudo apt-get install gcc-4.8 g++-4.8
$ export CXX=g++-4.8
```

#### Compile tippecanoe

```bash
$ cd $HOME
$ git clone git@github.com:geoadmin/tippecanoe.git
$ cd tippecanoe
$ make
```

### Create a new tileset

To create a new tileset you need one to many GeoJSON files in `ESPG:3857` in the same folder.

Let's use the file `sample/swissboundaries_gemeinde_3857.json`.

The process of a creating a new tileset involves 3 phases at the moment.
All these steps are performed via `scripts/process-tilesets.sh`

#### 1 Combine GeoJSONs

Create GeoJSON headers and if needed combine the geojson input files into one GeoJSON file (Note that this will work only if there is one line per `Feature` in the GeoJSON).

#### 2 Modify GeoJSON

Add [tippecanoe extensions](https://github.com/geoadmin/tippecanoe#geojson-extension).
We currently use it only the create the `"tippecanoe"` nested field for `minzoom` and `maxzoom` red from the initial GEOJSON file. `"properties": {"minzoom": 6, "maxzoom": 16}` becomes `"properties": { "tippecanoe" : {"minzoom": 6, "maxzzoom": 16} }`
This will tell tippecanoe at which zoom level each individual feature is available.

#### 3 Create the tileset

Create a new tile tileset with `.mbtiles` extension. (a sqlite3 database)
Here is a list of tippecanoe options we currently use to create a new tileset.

- The [tileset name](https://github.com/geoadmin/tippecanoe#output-tileset-1) `${tileset_name}`
- The [layer name](https://github.com/geoadmin/tippecanoe#tileset-description-and-attribution-1) which is `${tilesetname}-layer`
- The [preserve input order option](https://github.com/mapbox/tippecanoe#reordering-features-within-each-tile) which is then used on the client side to determine which feature should be displayed first in case they overlap.
- The [minimum and maximum tiling zooms](https://github.com/mapbox/tippecanoe#zoom-levels) for which tiles are generated.
- The [tileset description](https://github.com/mapbox/tippecanoe#tileset-description-and-attribution) which is `${tilesetname}-description`.
- The [filtering of certain properties](https://github.com/mapbox/tippecanoe#filtering-feature-attributes) of the input GeoJSON file. For production ready tilesets, properties in the resulting tileset should be kept to a bare minimum to optimize the size of vector tiles.
- [Type coercion](https://github.com/mapbox/tippecanoe#modifying-feature-attributes) of feature attributes (when input data is incorrect)

#### All in one script

```bash
$ ./scripts/process-tilesets.sh
Usage:

-h --help
--maxzoom        Maximum zoom level to generate tiles [default:15]
--minzoom        Minimum zoom level to generate tiles [default:6]
--inputs         List of input files [default:""]
--outputpath     Directory for output files [default: .]
--tilesetname    File pattern for output files [default: composite]

Usage example:
$ ./scripts/process-tilesets.sh --inputs="data/tiles/base.json data/tiles/adds.json" --outputpath=data/tiles --tilesetname=composite
```

Now try:

```bash
$ ./scripts/process-tilesets.sh --inputs="sample/swissboundaries_gemeinde_3857.json" --outputpath=sample --tilesetname=boundaries
```

This will create 3 files.

```bash
Composite JSON: sample/boundaries/[timestamp]/tiles.geojson
Modified JSON: sample/boundaries/[timestamp]/tiles_modified.geojson
Composite MBTile: sample/boundaries/[timestamp]/tiles.mbtiles
```

- The combined or composite GeoJSON (step 1)
- The modified GeoJSON with tippecanoe extensions (step 2)
- The new tileset containing the mbtiles (step 3)

### Publish a new tileset in tileserver-gl

[tileserver-gl](https://github.com/geoadmin/tileserver-gl) configuration is hold in `tileserver-gl/tileserver-gl-config.json`

#### 1 Add the tileset to EFS

Make sure your ssh identity has been forwarded.

```bash
$ ssh-add -L
```
Remove the intermediary files

```bash
rm sample/boundaries/[timestamp]/tiles.geojson sample/boundaries/[timestamp]/tiles_modified.geojson
```

Add the newly created tileset to [EFS](https://aws.amazon.com/efs/?nc1=h_ls).

```bash
$ scp -r sample/boundaries/ geodata@${SERVER}:/var/local/efs-dev/vectortiles/mbtiles/boundaries/
```

#### 2 Add the new tileset in tileserver-gl

There is no need to add the configuration manually. Whenever you start the server, it will update the configuration automatically.

#### 3 Test the new server configuration locally

Make sure you created a SSH tunnel via the `-L localhost:8134:localhost:8134` option.

Then create the docker containers locally via

```bash
$ make dockerpurge dockerrun
```

Open your browser at `localhost:8134`. In the section **DATA** you should now see the `boundaries` entry.

You can collect metdata about the tileset using the following REST endpoint: `/data/boundaries-test.json` (`/data/${dataID}.json`)

### Publish a new style in tileserver-gl

#### 1 Add your new or updated style in the config-tileserver-gl github repository.

Styles are base on [Mapbox Style Specification](https://www.mapbox.com/mapbox-gl-js/style-spec/)

Styles in the config-tileserver-gl repository are meant to be deployed by a script within that repository. After adding your style, run the script (read the doc in config-tileserver-gl to know how) and it will be part of the availables styles in the EFS.

Besides, if your style is present in the EFS, when running the project, the configuration will automatically include your new script.

#### 2 Test the new server configuration locally

```bash
$ make dockerpurge dockerrun
```

Open your browser at `localhost:8135`. In the section **STYLES** you should now see the `Test Swiss Boundaries` entry.

You can access the new style using the following REST endpoint: `/styles/style_name/version/style.json` (`/styles/${styleID}/${styleVersion}/style.json`)

## Update Maputnik

```bash
$ cd ~
$ git clone git@github.com:maputnik/editor.git
$ cd editor
$ npm install
$ npm run build
$ rm -rf  ~/service-tileservergl/nginx/maputnik
$ mv public ~/service-tileservergl/nginx/maputnik
```

Change the base

```bash
$ vi nginx/maputnik/index.html
```

Add the following line in the head section.

```html
<base href="/maputnik/">
```

Re-run the server then open your browser to http://localhost:8134/maputnik

```bash
$ make dockerpurge dockerrun
```
