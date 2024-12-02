#!/usr/bin/env python3
# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
r"""Stopgap script to generate some cores for the englishbreakfast toplevel.

All output files are written to $REPO_TOP/build/$TOPNAME-autogen/.
"""

import argparse
import sys
import yaml
import shutil
import subprocess
import os

try:
    from yaml import CSafeDumper as YamlDumper
except ImportError:
    from yaml import SafeDumper as YamlDumper


def write_core(core_filepath, generated_core):
    with open(core_filepath, 'w') as f:
        # FuseSoC requires this line to appear first in the YAML file.
        # Inserting this line through the YAML serializer requires ordered dicts
        # to be used everywhere, which is annoying syntax-wise on Python <3.7,
        # where native dicts are not sorted.
        f.write('CAPI=2:\n')
        yaml.dump(generated_core,
                  f,
                  encoding="utf-8",
                  Dumper=YamlDumper)
    print("Core file written to %s" % (core_filepath, ))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--files-root', required=True)
    parser.add_argument('--topname', required=True)

    args = parser.parse_args()
    topname = args.topname
    files_root = args.files_root

    # Call topgen.
    files_data = files_root + "/hw/" + topname + "/data/"
    files_out = os.path.abspath(files_root + "/build/" + topname + "-autogen/")
    shutil.rmtree(files_out, ignore_errors=True)
    os.makedirs(files_out, exist_ok=False)
    cmd = [files_root + "/util/topgen.py",  # "--verbose",
           "-t", files_data + topname + ".hjson",
           "-o", files_out]
    try:
        print("Running topgen.")
        subprocess.run(cmd,
                       check=True,
                       stdout=subprocess.PIPE,
                       stderr=subprocess.STDOUT,
                       universal_newlines=True)

    except subprocess.CalledProcessError as e:
        print("topgen failed: " + str(e))
        print(e.stdout)
        sys.exit(1)

    # Create core files.
    print("Creating core files.")

    # For some cores such IP package files, we need a separate dependency for the register file.
    # Combining this with the generated topgen core file below can lead to cyclic dependencies.

    # reg-only
    for ip in ['pinmux']:
        core_filepath = os.path.abspath(os.path.join(files_out, 'generated-%s.core' % ip))
        name = 'lowrisc:ip:%s_reggen' % ip,
        files = ['ip/%s/rtl/autogen/%s_reg_pkg.sv' % (ip, ip),
                 'ip/%s/rtl/autogen/%s_reg_top.sv' % (ip, ip)]
        generated_core = {
            'name': '%s' % name,
            'filesets': {
                'files_rtl': {
                    'depend': [
                        'lowrisc:ip:tlul',
                    ],
                    'files': files,
                    'file_type': 'systemVerilogSource'
                },
            },
            'targets': {
                'default': {
                    'filesets': [
                        'files_rtl',
                    ],
                },
            },
        }
        write_core(core_filepath, generated_core)

    # topgen
    nameparts = topname.split('_')
    if nameparts[0] == 'top' and len(nameparts) > 1:
        chipname = 'chip_' + '_'.join(nameparts[1:])
    else:
        chipname = topname

    core_filepath = os.path.abspath(os.path.join(files_out, 'generated-topgen.core'))
    generated_core = {
        'name': "lowrisc:systems:generated-topgen",
        'filesets': {
            'files_rtl': {
                'depend': [
                    # Ibex and OTBN constants
                    'lowrisc:ibex:ibex_pkg',
                    'lowrisc:ip:otbn_pkg',
                    # flash_ctrl
                    f'lowrisc:constants:{topname}_top_pkg',
                    'lowrisc:prim:util',
                    'lowrisc:ip:lc_ctrl_pkg',
                    'lowrisc:ip_interfaces:clkmgr_pkg',
                    'lowrisc:ip_interfaces:flash_ctrl_pkg',
                    f'lowrisc:opentitan:{topname}_pwrmgr_pkg',
                    'lowrisc:ip_interfaces:rstmgr_pkg',
                    'lowrisc:prim:clock_mux2',
                    # clkmgr
                    'lowrisc:prim:all',
                    'lowrisc:prim:clock_gating',
                    'lowrisc:prim:clock_buf',
                    'lowrisc:prim:clock_div',
                    # Top
                    # ast and sensor_ctrl not auto-generated, re-used from top_earlgrey
                    'lowrisc:systems:top_earlgrey_sensor_ctrl',
                    'lowrisc:systems:top_earlgrey_ast_pkg',
                    # TODO: absorb this into AST longerm
                    'lowrisc:systems:clkgen_xil7series',
                ],
                'files': [
                    # Top
                    'rtl/autogen/%s_rnd_cnst_pkg.sv' % topname,
                    'rtl/autogen/%s_pkg.sv' % topname,
                    'rtl/autogen/%s.sv' % topname,
                    # TODO: this is not ideal. we should extract
                    # this info from the target configuration and
                    # possibly generate separate core files for this.
                    'rtl/autogen/%s_cw305.sv' % chipname,
                ],
                'file_type': 'systemVerilogSource'
            },
        },
        'targets': {
            'default': {
                'filesets': [
                    'files_rtl',
                ],
            },
        },
    }
    write_core(core_filepath, generated_core)

    return 0


if __name__ == "__main__":
    main()
