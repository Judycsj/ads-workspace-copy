<!-- ads-workspace-gdoc-sync: gdoc_id=1ZsGxEpBBTUHN2jdJMKvifTKyeRvMG4nK72VC17lycp8 gdoc_url=https://docs.google.com/document/d/1ZsGxEpBBTUHN2jdJMKvifTKyeRvMG4nK72VC17lycp8/edit -->

### Note

There is an issue with protobuf wherein if this library is imported by other repos there will be complaint for
namespace conflict. So you will need to run a script to prepend package name to the `.proto` files.

Run `proto-compile` first. You can then run `make proto-validate` to validate.