#!/usr/bin/python
import subprocess
import sys
import os
import datetime

def shellquote(s):
    return "'" + s.replace("'", "'\\''") + "'"

if len(sys.argv)>1:
    output_dir=sys.argv[1]
else:
    print('Usage: {0} output_path <from_commit> <to_commit>'.format(sys.argv[0]))
    sys.exit()

if len(sys.argv)>2:
    from_commit = sys.argv[2]
else:
    from_commit=''

if len(sys.argv)>3:
    to_commit = sys.argv[3]
else:
    p = subprocess.Popen('git log master -n 1 --pretty=format:%H', shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    lines = []
    for line in p.stdout.readlines():
        lines.append(line.strip())
        
    if len(lines)!=1:
        print('Error finding HEAD commit {0}'.format(', '.join(lines)))
        sys.exit()
    to_commit = lines[0]
    
if not os.path.exists(output_dir):
    print('Output path does not exist: {0}'.format(output_dir))
    sys.exit()
    
base_file = 'deploy-{0}-{1}'.format(from_commit,to_commit)
    
output_tmp = os.path.join(output_dir, base_file + '.tar')
output_archive = os.path.join(output_dir, base_file + '.tar.bz2')
output_script = os.path.join(output_dir, base_file + '.sh')
    
if os.path.exists(output_tmp):
    print('Temp restore archive already exists: {0}'.format(output_tmp))
    sys.exit()

if os.path.exists(output_archive):
    print('Restore archive already exists: {1}'.format(output_archive))
    sys.exit()
    
if os.path.exists(output_script):
    print('Restore script already exists: {2}'.format(output_script))
    sys.exit()
    
changes=[]

print('Creating migration package for {0} to {1}'.format(from_commit, to_commit))
print('------------')

print('Generating changelist...')
p = subprocess.Popen('git diff --name-status {0} {1}'.format(from_commit,to_commit), shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
for line in p.stdout.readlines():
    changes.append(line.strip())
retval = p.wait()

print('Building changeset...')

archive_created = False

out_file = open(output_script, 'w')

out_file.write('# generated on {0}\n'.format(datetime.datetime.now()))
out_file.write('# migrating from {0} to {1}\n'.format(from_commit, to_commit))

added = 0
modified = 0
deleted = 0

for change in changes:
    parts=change.split('\t',2)
    if len(parts)==2:
        change_type=parts[0].strip()
        change_target=parts[1].strip()
        
        if change_type=='M' or change_type=='A':
            #add file to the tar archive
            cmd = 'tar -' + ('r' if archive_created else 'c') + 'f ' + shellquote(output_tmp) + ' ' + shellquote(change_target)
            subprocess.call(cmd, shell=True)
            archive_created = True
            
            if change_type=='M':
                modified+=1
            elif change_type=='A':
                added+=1
            
        if change_type=='D':
            #store delete command
            cmd = 'rm ' + shellquote(change_target)
            out_file.write(cmd + '\n')
            
            deleted+=1

        print('{0}:{1}'.format(change_type,change_target))

print('------------')        
print('{0} added, {1} modified, {2} deleted'.format(added, modified, deleted))

cmd = 'bzip2 ' + shellquote(output_tmp)
subprocess.call(cmd, shell=True)

cmd = 'tar -xvjf ' + shellquote(base_file + '.tar.bz2')

out_file.write(cmd + '\n')

out_file.close()
