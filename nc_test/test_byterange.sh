#!/bin/sh

if test "x$srcdir" = x ; then srcdir=`pwd`; fi
. ../test_common.sh

set -e

# Test Urls
URL3="https://thredds-test.unidata.ucar.edu/thredds/fileServer/pointData/cf_dsg/example/point.nc#mode=bytes&aws.profile=none"
#URL3a="https://remotetest.unidata.ucar.edu/thredds/fileServer/testdata/2004050300_eta_211.nc#bytes&aws.profile=none"
URL4a="https://s3.us-east-1.amazonaws.com/noaa-goes16/ABI-L1b-RadC/2017/059/03/OR_ABI-L1b-RadC-M3C13_G16_s20170590337505_e20170590340289_c20170590340316.nc#mode=bytes&aws.profile=none"
URL4b="https://thredds-test.unidata.ucar.edu/thredds/fileServer/irma/metar/files/METAR_20170910_0000.nc#bytes&aws.profile=none"
URL4c="s3://noaa-goes16/ABI-L1b-RadC/2017/059/03/OR_ABI-L1b-RadC-M3C13_G16_s20170590337505_e20170590340289_c20170590340316.nc#mode=bytes&aws.profile=none"
# Requires auth
URL3b="s3://unidata-zarr-test-data/byterangefiles/upload3.nc#bytes&aws.profile=unidata"
URL4d="s3://unidata-zarr-test-data/byterangefiles/upload4.nc#bytes&aws.profile=unidata"
# Do not use unless we know it has some permanence (note the segment 'testing' in the URL);
URL4x="https://s3.us-west-2.amazonaws.com/coawst-public/testing/HadCRUT.4.6.0.0.median.nc#mode=bytes,&aws.profile=none"

echo ""

testsetup() {
U=$1
# Create and upload test files
if test "x$FEATURE_S3TESTS" = xyes ; then
rm -f upload4.nc upload3.nc
${execdir}/../nczarr_test/s3util clear -u ${U} -k /byterangefiles
${NCGEN} -lb -3 ${srcdir}/nc_enddef.cdl
mv nc_enddef.nc upload3.nc
${execdir}/../nczarr_test/s3util upload -u ${U} -k /byterangefiles/upload3.nc -f upload3.nc
if test "x$FEATURE_HDF5" = xyes ; then
${NCGEN} -lb -4 ${srcdir}/nc_enddef.cdl
mv nc_enddef.nc upload4.nc
${execdir}/../nczarr_test/s3util upload -u ${U} -k /byterangefiles/upload4.nc -f upload4.nc
fi
fi
rm -f tst_http_nc3.cdl tst_http_nc4?.cdl 
}

testcleanup() {
U=$1
rm -f upload4.nc upload3.nc
if test "x$FEATURE_S3TESTS" = xyes ; then
${execdir}/../nczarr_test/s3util clear -u ${U} -k /byterangefiles
fi
}

testbytes() {
TAG="$1"
EXPECTED="$2"
U="$3"
K=`${NCDUMP} -k "$U" | tr -d '\r'`
if test "x$K" != "x$EXPECTED" ; then
   echo "test_http: -k flag mismatch: expected=$EXPECTED have=$K"
   exit 1
fi
rm -f tst_http_$TAG.cdl
# Now test the reading of at least the metadata
${NCDUMP} -h "$U" >tst_http_$TAG.cdl
# compare
diff -wb tst_http_$TAG.cdl ${srcdir}/ref_tst_http_$TAG.cdl 
}

tests3auth() {
TAG="$1"
EXPECTED="$2"
U="$3"
K=`${NCDUMP} -k "$U" | tr -d '\r'`
if test "x$K" != "x$EXPECTED" ; then
   echo "test_http: -k flag mismatch: expected=$EXPECTED have=$K"
   exit 1
fi
rm -f tmp_${TAG}.cdl
# Now test the reading of at least the metadata
${NCDUMP} -n nc_enddef "$U" >tmp_${TAG}.cdl
# compare
diff -wb tmp_$TAG.cdl ${srcdir}/nc_enddef.cdl 
}

testsetup https://s3.us-east-1.amazonaws.com/unidata-zarr-test-data 

echo "*** Testing reading NetCDF-3 file with http"

echo "***Test remote classic file"
testbytes nc3 classic "$URL3"

if test "x$FEATURE_HDF5" = xyes ; then
    echo "***Test remote netcdf-4 file: non-s3"
    testbytes nc4b netCDF-4 "$URL4b"
fi
if test "x$FEATURE_S3TESTS" = xyes && test "x$FEATURE_HDF5" = xyes ; then
    echo "***Test remote netdf-4 file: s3"
    testbytes nc4a netCDF-4 "$URL4a"
    echo "***Test remote netcdf-4 file: s3"
    testbytes nc4c netCDF-4 "$URL4c"
    echo "***Test remote netcdf-4 file: s3 auth"
    tests3auth nc4d netCDF-4 "$URL4d"
fi
if test "x$FEATURE_S3TESTS" = xyes ; then
  echo "***Test remote netcdf-3 file: s3 auth"
  tests3auth nc3b classic "$URL3b"
fi

# Cleanup
testcleanup https://s3.us-east-1.amazonaws.com/unidata-zarr-test-data

exit
