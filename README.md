# Card-Cutter
PowerShell script &amp; corresponding executable that create navigation (PCMCIA) cards for aviation purposes

---

This program searches for a FAT formatted media which is compatible with specific aviation systems. Upon locating the media and ensuring the presence of DAFIF (Digital Aeronautical Flight Information File) directory on the corresponding system's desktop, it formats the media, labels it based on the directory name, and writes all of the DAFIF and navigation files. The program also performs a data integrity check on all of the associated files. Should the integrity check fail, an error report listing the discrepancy is produced in a standard flat file.
