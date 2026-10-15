# Onepanel REST API defined using Swagger (http://swagger.io)

This repo contains Swagger specification of Oneprovider REST API.

Onepanel is part of [Onedata](http://onedata.org), a distributed data management platform. Onepanel is an administrative service which enables management of other Onedata services including [Onezone](http://github.com/onedata/onezone) and [Oneprovider](http://github.com/onedata/oneprovider).

For more details about Onepanel service please check (http://github.com/onedata/onepanel).

Compiling (Using Onedata docker repository):
```
./build.sh
```

Compiling from scratch:
```
# Install Node.js dependencies
npm install

# Aggregate Yaml specification files into a single swagger.json file
node resolve.js > swagger.json
```

After any of these steps you should have a complete `swagger.json` file, with specification of Onepanel REST API. The file can be used by Swagger [code generator](https://github.com/swagger-api/swagger-codegen) to produce example code for clients in various languages or viewed online using for instance [Swagger Online Editor](http://editor.swagger.io/).

## Onedata Swagger extensions

The `x-onedata-*` properties provide Onedata-specific metadata in addition to the standard Swagger schema. The descriptions below are based on their use in this repository's definitions and Erlang code generation templates ([rest_model.mustache](rest_model.mustache) and [rest_api.mustache](rest_api.mustache)).

| Extension | Purpose |
| --- | --- |
| `x-onedata-datatype` | Overrides the inferred property type in the generated Erlang parser specification. Values use Erlang syntax, for example `[ip4]` for a list of IPv4 addresses or `#{}` for a map. |
| `x-onedata-default-value` | Supplies the default for an optional property or parameter in the generated Erlang parser specification. Values are Erlang expressions, such as `<<"auto">>`, `[]`, or `#{}`, rather than the JSON values used by Swagger's `default`. |
| `x-onedata-dictionary` | Marks an object as a dictionary with arbitrary keys and a common value type, described by `additionalProperties` and `x-onedata-dictionary-value-type`. The local model template uses the value-type extension to generate dictionary handling. |
| `x-onedata-dictionary-value-type` | Identifies the type of each dictionary value, for example `service_status_host`, `storage_create_details`, or `string`. For model-level dictionaries, the Erlang template generates a wildcard-key map referencing the corresponding `<type>_model()` function. |
| `x-onedata-gri` | Associates an API operation with an Onedata Graph Resource Identifier (GRI). The route template uses its `type`, `id`, `aspect`, and optional `scope` to construct a bound GRI (`#b_gri{}`); `id` can refer to a URL binding such as `?BINDING(id)`. Omitted `id` and `scope` default to `undefined` and `private`, respectively. |
| `x-onedata-oneof` | Marks a model as a choice among the models listed in `x-onedata-subclasses`. The Erlang template generates a parser specification using `onepanel_parser:prepare_subclasses`, rather than a fixed object specification. Used with discriminator-based models such as storage configurations. |
| `x-onedata-runtime-mutable` | Marks a storage property as intended to be safe to change while the storage is actively used. If this flag is not set on a property, it is assumed false, i.e. the give storage property is immutable (e.g. storagePathType) or requires all storage operations to be stopped during change to ensure data safety. |
| `x-onedata-storage` | Marks a storage model for special handling in the Erlang model template. Allows properties marked with `x-onedata-storage-param` to be included in the parser specification even when they are marked `readOnly`. Used on storage GET models. |
| `x-onedata-storage-param` | Marks an individual storage parameter for the special inclusion enabled by `x-onedata-storage`, for example `timeout` or `lumaFeed` in `StorageGetDetails`. |
| `x-onedata-subclasses` | Lists the alternative model names for an `x-onedata-oneof` model, using generated Erlang naming such as `posix_get` or `s3_get`. The template calls each listed model's `<name>_model()` function to build the alternatives. |
