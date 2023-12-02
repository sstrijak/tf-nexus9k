import os, sys
from jinja2 import Environment, FileSystemLoader

serial = ''
mgmtip = ''
if len(sys.argv) > 1: serial=sys.argv[1]
if len(sys.argv) > 2: swname=sys.argv[2]
if len(sys.argv) > 3: mgmtip=sys.argv[3]
if serial=='' or mgmtip == '' or swname=='':
  quit ('usage: poap.py <serial> <switchname> <mgmtip>')

environment = Environment(loader=FileSystemLoader("templates/"))
template = environment.get_template("poap.j2")

content = template.render(
  hostname = swname,
  serial = serial,
  mgmtip = mgmtip
)

filename = 'conf.'+serial
with open ( filename,  mode="w", encoding="utf-8") as config:
  config.write(content)
  print(f"... wrote {filename}")

os.system(f"md5sum {filename} > {filename}.md5")
print(f"... calculated md5 for {filename}" )

os.system(f"mv {filename}* /tftpboot/configs/")
print(f"... moved {filename} to /tftpboot" )


