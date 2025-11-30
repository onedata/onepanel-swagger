#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
This script processes swagger.json to flatten allOf at the property level.

Swagger Codegen 2.x doesn't properly merge properties from allOf when used
at the field level (inside properties). This script merges such allOf arrays
into single property definitions while preserving the original field order.

Example transformation:
    "timeout": {
      "allOf": [
        {"type": "integer", "description": "..."},
        {"x-onedata-storage-param": true, "readOnly": true}
      ]
    }

becomes:
    "timeout": {
      "type": "integer",
      "description": "...",
      "x-onedata-storage-param": true,
      "readOnly": true
    }
"""

import json
import sys


def merge_allof(items):
    """
    Merge a list of schema objects into one, preserving key order.
    Keys from earlier items appear first, then keys from later items.
    """
    result = {}
    for item in items:
        if isinstance(item, dict):
            for key, value in item.items():
                if key == 'allOf':
                    # Recursively merge nested allOf
                    merged = merge_allof(value)
                    for k, v in merged.items():
                        if k not in result:
                            result[k] = v
                        elif isinstance(result[k], dict) and isinstance(v, dict):
                            result[k] = {**result[k], **v}
                        elif isinstance(result[k], list) and isinstance(v, list):
                            # Merge lists preserving order, removing duplicates
                            seen = set(result[k])
                            result[k] = result[k] + [x for x in v if x not in seen]
                        else:
                            result[k] = v
                elif key not in result:
                    result[key] = value
                elif isinstance(result[key], dict) and isinstance(value, dict):
                    # Deep merge for nested dicts
                    result[key] = {**result[key], **value}
                elif isinstance(result[key], list) and isinstance(value, list):
                    # Merge lists preserving order
                    seen = set(result[key])
                    result[key] = result[key] + [x for x in value if x not in seen]
                else:
                    # Later values override earlier ones
                    result[key] = value
    return result


def flatten_property_allof(obj):
    """
    Recursively process the swagger spec and flatten allOf at property level.
    Preserves the original order of properties.
    """
    if isinstance(obj, dict):
        # Check if this is a property definition with only allOf
        if 'allOf' in obj and len(obj) == 1:
            # This object only has allOf - merge it
            merged = merge_allof(obj['allOf'])
            # Recursively process the merged result
            return flatten_property_allof(merged)

        # Process all keys recursively, preserving order
        result = {}
        for key, value in obj.items():
            if key == 'properties' and isinstance(value, dict):
                # Process properties - this is where field-level allOf appears
                result[key] = {}
                for prop_name, prop_value in value.items():
                    if isinstance(prop_value, dict) and 'allOf' in prop_value and len(prop_value) == 1:
                        # Flatten the allOf for this property
                        merged = merge_allof(prop_value['allOf'])
                        result[key][prop_name] = flatten_property_allof(merged)
                    else:
                        result[key][prop_name] = flatten_property_allof(prop_value)
            else:
                result[key] = flatten_property_allof(value)
        return result
    elif isinstance(obj, list):
        return [flatten_property_allof(item) for item in obj]
    else:
        return obj


def main():
    input_file = sys.argv[1] if len(sys.argv) > 1 else 'swagger.json'

    with open(input_file, 'r') as f:
        swagger = json.load(f)

    # Only process definitions section
    if 'definitions' in swagger:
        swagger['definitions'] = flatten_property_allof(swagger['definitions'])

    # Write back to the same file (in-place modification)
    with open(input_file, 'w') as f:
        json.dump(swagger, f, indent=2)

    print(f"Fixed allOf in properties: {input_file}")


if __name__ == '__main__':
    main()
