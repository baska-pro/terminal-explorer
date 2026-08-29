# Safety

Terminal Explorer performs file operations selected by the user.

## Protected paths

The delete helper refuses important roots such as:

```text
/
$HOME
/bin
/boot
/dev
/etc
/lib
/lib64
/proc
/root
/run
/sbin
/sys
/usr
/var
```

On Termux, important `$PREFIX` roots are protected as well.

## Confirmation

Destructive or replacement operations require confirmation where applicable.

## Archive extraction

Archive entries are checked for unsafe absolute paths and `../` traversal before extraction.

## Symlinks

Symlinks are displayed separately. Delete operations remove the symlink itself rather than recursively deleting the linked target.

## Scope

The protection layer reduces accidental deletion through Terminal Explorer; it is not an operating-system sandbox. A shell command launched manually from the Run function has the same permissions as the current user.
