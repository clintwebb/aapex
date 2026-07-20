This is typically for files that will be the same across all environments.  However, some may be overwritten with the logic where it searches for multiple files, and chooses the first one it finds.

For example:

```
- name: Copy file
  copy:
    src: "{{ lookup('ansible.builtin.first_found', findme) }}"
    dest: /some/file.txt
  vars:
    findme:
      - "files/{{ env }}/some/file.txt"
      - files/base/some/file.txt

```

