##########################################
# WildCo Image Renaming.R
# Updated Aug. 20, 2020 - Chris B
#########################################

# YOU WILL NEED ADMINISTRATOR PRIVILEGES TO USE THIS SCRIPT #

# Install perl prior to exifr installation from http://strawberryperl.com/

# Install the exif tool from https://exiftool.org/

#install.packages("exifr")
library(exifr)
# Should say "Using ExifTool version XX.X" - if it doesn't, make you have admin privilages and reinstall

#install.packages("stringr")
library(stringr)
#install.packages("R.utils")
library(R.utils)


################################
##### createStationFolders #####
## Extract the list of station folders to be renames

# If you are not working within  the WildCo "Example Codes" project you will need to set a working directory. 
# You *should* work inside the project though!
getwd()

# The following two must be edited if you want to use a new folder

# Specify the folder images you want to rename (organised by station)
to_be_renamed <- "Test_Images_Original"
# Specify the location you want the renamed images to go (originals are left untouched)
renamed_location <- "Test_Images_Renamed" 

################################
################################

# Create a folder to copy the original images into
dir.create(renamed_location)

# Copy over the files
copyDirectory(to_be_renamed, renamed_location, private=TRUE, recursive=TRUE)

#Check the exif tool is working on the original data
test <- list.files(path = renamed_location,
                   full.names = T, include.dirs = F, recursive = T)[1]

read_exif(test, tags = c("DateTimeOriginal"), recursive = F, quiet = TRUE)

# You should see a tibble containing the file names and DateTimeOriginal
# If this doesnt work - check your exif installation!


# Get a list of the folders to be renamed
Folders <- list.dirs(path = renamed_location,
                     full.names = FALSE)

# Remove the empty argument
Folders <- Folders[Folders!=""]

# Remove any hollow folders -> folders that don't contain images (e.g. if you are using nested folders, some folders will just contain directories)
for(i in 1: length(Folders))
{
  tmp <-  dir.exists(list.files(path = paste0(renamed_location, "//",Folders[i]),
                       full.names = T, include.dirs = T))
  # Remove folders that just contain folders
  if(length(tmp[tmp==TRUE])>0)
  {
    Folders[i] <- "" 
  }
  # Remove folders that dont contain anything
  if(length(tmp)==0)
  {
    Folders[i] <- "" 
  }
}
Folders <- Folders[Folders!=""]

##### imageRename #####
# Sometimes we have a lot of files and renaming can take a long time, so lets do this folder by folder 
# This will enable you to see progress updates

for(i in 1:length(Folders))
{
  # Read in the files
  tmp.locs <- list.files(path = paste0(renamed_location, "//",Folders[i]),
                                      full.names = T, include.dirs = T)
  # Replace colons with dashes
  tmp.exif <- read_exif(tmp.locs, tags = c("DateTimeOriginal"), recursive = F, quiet = TRUE)
  tmp.exif$DateTimeOriginal <- str_replace_all(tmp.exif$DateTimeOriginal, ":", "-")
  
  new.names<- paste0(renamed_location,"//", Folders[i], "//", 
                     strsplit(Folders[i], "/")[[1]][1], "__",                # The station name (the first element in the string if nested folders are used)
                     gsub( " .*$", "", tmp.exif$DateTimeOriginal), "__",     # The day
                     sub(".*? ", "", tmp.exif$DateTimeOriginal), ".jpg")     # The time 
  
  # if any files have the same name, add a counter (_#) to make it unique
  dups <- new.names[duplicated(new.names)]
  # Subset to the unique values
  dups <- unique(dups)
  # For each duplicate add a counter
 
  if(length(dups) > 0)
  {
    for(j in 1:length(dups))
    {
      n.dups <- length(new.names[new.names==dups[j]])
      new.names[new.names==dups[j]] <- paste0(sub("[.].*", "", new.names[new.names==dups[j]]),"_",1:n.dups, ".jpg")
    }
  }
  
  # Raname the images
  file.rename(tmp.locs, new.names)
  # Counter
  print(paste(i ,"Folders(s) renamed"))    
}

# Check a folder to see if it has worked
