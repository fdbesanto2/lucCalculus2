library(lucCalculus)

# always
options(digits = 12)

#----------------------------
# 1- Open idividual images and create a RasterBrick with each one and metadata with SITS
#----------------------------

# create a RasterBrick from individual raster saved previously
lucC_create_RasterBrick(path_open_GeoTIFFs = "inst/extdata/raster/rasterItanhanga", path_save_RasterBrick = "inst/extdata/raster")

# ------------- define variables to use in sits -------------
# open files
file <- c("inst/extdata/raster/rasterItanhanga.tif")
file

# create timeline with classified data from SVM method
timeline <- lubridate::as_date(c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01", "2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01", "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01", "2016-09-01"))
timeline

#library(sits)
# create a RasterBrick metadata file based on the information about the files
raster.tb <- sits::sits_coverage(files = file, name = "Itanhanga", timeline = timeline, bands = "ndvi")
raster.tb

# new variable
rb_sits <- raster.tb$r_objs[[1]][[1]]
rb_sits


# ------------- define variables to plot raster -------------
# original label - see QML file, same order
#label <- as.character(c("Cerrado", "Crop_Cotton", "Fallow_Cotton", "Forest", "Pasture1", "Pasture2", "Pasture3", "Soybean_Cotton", "Soybean_Crop1", "Soybean_Crop2", "Soybean_Crop3", "Soybean_Crop4", "Soybean_Fallow1", "Soybean_Fallow2", "Water", "Water_mask"))
label <- as.character(c("Cerrado", "Double_cropping", "Single_cropping", "Forest", "Pasture", "Pasture", "Pasture", "Double_cropping", "Double_cropping", "Double_cropping", "Double_cropping", "Double_cropping", "Single_cropping", "Single_cropping", "Water", "Water"))
label

# colors
#colors_1 <- c("#b3cc33", "#d1f0f7", "#8ddbec", "#228b22", "#afe3c8", "#7ecfa4", "#64b376", "#e1cdb6", "#b6a896", "#b69872", "#b68549", "#9c6f38", "#e5c6a0", "#e5a352", "#0000ff", "#3a3aff")
colors_1 <- c("#BEEE53", "#cd6155", "#e6b0aa", "#228b22", "#7ecfa4", "#afe3c8",  "#64b376", "#e1cdb6", "#b6a896", "#b69872", "#b68549", "#9c6f38", "#e5c6a0", "#e5a352", "#0000ff", "#3a3aff")
colors_1

# plot raster brick
lucC_plot_raster(raster_obj = rb_sits,
                 timeline = timeline, label = label,
                 custom_palette = TRUE, RGB_color = colors_1, plot_ncol = 5)

# change pixel of water by Cerrado, because this class doesn't exist in this municipality
rb_sits <- raster::reclassify(rb_sits, cbind(15, 1))
rb_sits

lucC_plot_raster(raster_obj = rb_sits,
                 timeline = timeline, label = label,
                 custom_palette = TRUE, RGB_color = colors_1, plot_ncol = 5)

# select some layers
rb_sits
layers <- c(1, 3, 5, 7, 9, 11, 13, 15)
rb_sits_2years <- raster::subset(rb_sits, layers)
rb_sits_2years

# create timeline with classified data from SVM method
timeline_n <- lubridate::as_date(c("2001-09-01", "2003-09-01", "2005-09-01", "2007-09-01", "2009-09-01", "2011-09-01", "2013-09-01", "2015-09-01"))
timeline_n

png(filename = "~/Desktop/fig_TESE/fig_ita_land_use2D.png", width = 6.7, height = 5.4, units = 'in', res = 300)
lucC_plot_raster(raster_obj = rb_sits_2years,
                 timeline = timeline_n, label = label,
                 custom_palette = TRUE, RGB_color = colors_1, plot_ncol = 3,
                 relabel = TRUE, original_labels = c("Cerrado", "Double_cropping", "Single_cropping", "Forest", "Pasture"), new_labels =  c("Degradation", "Double cropping", "Single cropping", "Forest", "Pasture") )
dev.off()



#----------------------------
# 2- Discover Secondary Vegetation - LUC Calculus
#----------------------------

# 1. Verify if forest RECUR ins econd interval
system.time(
  forest_recur <- lucC_pred_recur(raster_obj = rb_sits, raster_class = "Forest",
                                  time_interval1 = c("2001-09-01","2001-09-01"),
                                  time_interval2 = c("2002-09-01","2016-09-01"),
                                  label = label, timeline = timeline)
)

head(forest_recur)

# 2. Verify if occur forest EVOLVE from a different class in 2001
forest_evolve <- NULL
# classes without Forest
#classes <- as.character(c("Cerrado", "Crop_Cotton", "Fallow_Cotton", "Pasture1", "Pasture2", "Pasture3", "Soybean_Cotton", "Soybean_Crop1", "Soybean_Crop2", "Soybean_Crop3", "Soybean_Crop4", "Soybean_Fallow1", "Soybean_Fallow2", "Water", "Water_mask"))
classes <- as.character(c("Cerrado", "Double_cropping", "Single_cropping", "Pasture", "Pasture", "Pasture", "Double_cropping", "Double_cropping", "Double_cropping", "Double_cropping", "Double_cropping", "Single_cropping", "Single_cropping", "Water", "Water"))

# percor all classes
system.time(
  for(i in seq_along(classes)){
    print(classes[i])
    temp <- lucC_pred_evolve(raster_obj = rb_sits, raster_class1 = classes[i],
                             time_interval1 = c("2001-09-01","2001-09-01"), relation_interval1 = "equals",
                             raster_class2 = "Forest",
                             time_interval2 = c("2002-09-01","2016-09-01"), relation_interval2 = "contains",
                             label = label, timeline = timeline)

    forest_evolve <- lucC_merge(forest_evolve, temp)
  }
)

head(forest_evolve)

# 3. Merge both forest_recur and forest_evolve datas
forest_secondary <- lucC_merge(forest_evolve, forest_recur)
head(forest_secondary)

lucC_plot_bar_events(forest_secondary, custom_palette = FALSE, pixel_resolution = 232, legend_text = "Legend:")

# 4. Remove column 2001 because it' is not used to replace pixels's only support column
forest_sec <- lucC_remove_columns(data_mtx = forest_secondary, name_columns = c("2001-09-01"))
head(forest_sec)

lucC_plot_bar_events(forest_sec, custom_palette = FALSE, pixel_resolution = 232, legend_text = "Legend:")

# 5. Plot secondary vegetation over raster without column 2001 because it' is not used to replace pixels's only support column
lucC_plot_raster_result(raster_obj = rb_sits,
                        data_mtx = forest_sec,
                        timeline = timeline,
                        label = label, custom_palette = TRUE,
                        RGB_color = colors_1, relabel = FALSE, shape_point = ".")


# create images output
lucC_save_raster_result(raster_obj = rb_sits,
   data_mtx = forest_sec,       # without 2001
   timeline = timeline, label = label, path_raster_folder = "~/Desktop/rasterItanhangaSec") # new pixel value

lucC_save_raster_result(raster_obj = rb_sits,
                        data_mtx = forest_evolve,       # without 2001
                        timeline = timeline, label = label, path_raster_folder = "~/Desktop/rasterItanhangaEvo") # new pixel value


#----------------------------
# 3- Update original raster to add new pixel value
#----------------------------

rm(forest_evolve, forest_recur, forest_secondary, raster.tb)
gc()

n_label <- length(label) + 1

# 1. update original RasterBrick with new class
rb_sits_new <- lucC_raster_update(raster_obj = rb_sits,
                                  data_mtx = forest_sec,       # without 2001
                                  timeline = timeline,
                                  class_to_replace = "Forest",  # only class Forest
                                  new_pixel_value = n_label)         # new pixel value

head(rb_sits_new)

lucC_plot_bar_events(data_mtx = rb_sits_new, pixel_resolution = 232, custom_palette = FALSE)

# 2. save the update matrix as GeoTIFF images
lucC_save_GeoTIFF(raster_obj = rb_sits,
                  data_mtx = rb_sits_new,
                  path_raster_folder = "inst/extdata/raster/rasterItanhangaSecVeg", as_RasterBrick = FALSE)
                  #path_raster_folder = "~/Desktop/rasterItanhangaSecVeg", as_RasterBrick = FALSE)


#===================================================================================================
#===================================================================================================
#----------------------------
# 4- Open idividual images reclassified and create a RasterBrick with each one and metadata ith SITS
#----------------------------

library(lucCalculus)

# always
options(digits = 12)

# create a RasterBrick from individual raster saved previously
lucC_create_RasterBrick(path_open_GeoTIFFs = "inst/extdata/raster/rasterItanhangaSecVeg", path_save_RasterBrick = "inst/extdata/raster")

# ------------- define variables to use in sits -------------
# open files with new pixel secondary vegetation
file <- c("inst/extdata/raster/rasterItanhangaSecVeg.tif")
file

# create timeline with classified data from SVM method
timeline <- lubridate::as_date(c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01", "2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01", "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01", "2016-09-01"))
timeline

#library(sits)
# create a RasterBrick metadata file based on the information about the files
raster.tb <- sits::sits_coverage(files = file, name = "ItaVegSec", timeline = timeline, bands = "ndvi")
raster.tb

# new variable
rb_sits2 <- raster.tb$r_objs[[1]][[1]]
rb_sits2

# new class Seconary vegetation
label2 <- as.character(c("Cerrado", "Double_cropping", "Single_cropping", "Forest", "Pasture", "Pasture", "Pasture", "Double_cropping", "Double_cropping", "Double_cropping", "Double_cropping", "Double_cropping", "Single_cropping", "Single_cropping", "Water", "Water", "Secondary_vegetation"))
label2

# colors
colors_2 <- c("#BEEE53" , "#cd6155", "#e6b0aa", "#228b22", "#7ecfa4", "#1e174d", "#afe3c8", "#64b376", "#e1cdb6", "#b6a896", "#b69872", "#b68549", "#9c6f38", "#e5c6a0", "#e5a352", "#0000ff", "#3a3aff") # "#b3cc33" "#228b22", "#7ecfa4", "blue"

# plot raster brick
lucC_plot_raster(raster_obj = rb_sits2,
                 timeline = timeline, label = label2,
                 custom_palette = TRUE, RGB_color = colors_2, plot_ncol = 6)

#------------------------------------
# select some layers
layers <- c(1, 3, 5, 7, 9, 11, 13, 15)
rb_sits_2years <- raster::subset(rb_sits2, layers)
rb_sits_2years

# create timeline with classified data from SVM method
timeline_n <- lubridate::as_date(c("2001-09-01", "2003-09-01", "2005-09-01", "2007-09-01", "2009-09-01", "2011-09-01", "2013-09-01", "2015-09-01"))
timeline_n

png(filename = "~/Desktop/fig_TESE/fig_ita_land_use_SV2D.png", width = 6.7, height = 5.4, units = 'in', res = 300)
lucC_plot_raster(raster_obj = rb_sits_2years,
                 timeline = timeline_n, label = label2,
                 custom_palette = TRUE, RGB_color = colors_2, plot_ncol = 3,
                 relabel = TRUE, original_labels = c("Cerrado", "Double_cropping", "Single_cropping", "Forest", "Pasture", "Secondary_vegetation"), new_labels =  c("Degradation", "Double cropping", "Single cropping", "Forest", "Pasture", "Secondary vegetation"))
dev.off()




#----------------------------
# 5- Discover Forest and Secondary vegetation - LUC Calculus
#----------------------------

secondary.mtx <- lucC_pred_holds(raster_obj = rb_sits2, raster_class = "Secondary_vegetation",
                                 time_interval = c("2001-09-01","2016-09-01"),
                                 relation_interval = "contains", label = label2, timeline = timeline)
head(secondary.mtx)

forest.mtx <- lucC_pred_holds(raster_obj = rb_sits2, raster_class = "Forest",
                              time_interval = c("2001-09-01","2016-09-01"),
                              relation_interval = "contains", label = label2, timeline = timeline)
head(forest.mtx)

Forest_secondary.mtx <- lucC_merge(secondary.mtx, forest.mtx)
head(Forest_secondary.mtx)

# plot results
png(filename = "~/Desktop/fig_TESE/ita_bar_for_SV.png", width = 6.5, height = 4.5, units = 'in', res = 300)
lucC_plot_bar_events(data_mtx = Forest_secondary.mtx, custom_palette = TRUE, RGB_color = c("black", "gray60"), #c("#228b22", "#7ecfa4"),
                     pixel_resolution = 231.656, side_by_side = TRUE,
                     relabel = TRUE, original_labels = c("Forest", "Secondary_vegetation"),
                     new_labels = c("Forest", "Secondary vegetation"))
# forest evolved and recur
dev.off()


lucC_plot_frequency_events(data_mtx = Forest_secondary.mtx,
                     pixel_resolution = 231.656, custom_palette = FALSE)

# Compute values
measuresFor_Sec <- lucC_result_measures(data_mtx = Forest_secondary.mtx, pixel_resolution = 232)
measuresFor_Sec



#----------------------------
# 6- Discover Land use transitions - LUC Calculus
#----------------------------
# create timeline with classified data from SVM method
timeline <- lubridate::as_date(c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01", "2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01", "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01", "2016-09-01"))
timeline

label2 <- as.character(c("Cerrado", "Crop_Cotton", "Fallow_Cotton", "Forest", "Pasture", "Pasture", "Pasture", "Soy", "Soy", "Soy", "Soy", "Soy", "Soy", "Soy", "Water", "Water", "Secondary_vegetation"))
label2

class1 <- c("Forest")
classes <- c("Pasture", "Soy", "Secondary_vegetation") #

direct_transi.df <- NULL

# along of all classes
system.time(
  for(x in 2:length(timeline)){
    t_1 <- timeline[x-1]
    t_2 <- timeline[x]
    cat(paste0(t_1, ", ", t_2, sep = ""), "\n")

    # moves across all classes
    for(i in seq_along(classes)){
      cat(classes[i], collapse = " ", "\n")
      temp <- lucC_pred_convert(raster_obj = rb_sits2, raster_class1 = class1,
                                time_interval1 = c(t_1,t_1), relation_interval1 = "equals",
                                raster_class2 = classes[i],
                                time_interval2 = c(t_2,t_2), relation_interval2 = "equals",
                                label = label2, timeline = timeline)

      if (!is.null(temp)) {
        temp <- lucC_remove_columns(data_mtx = temp, name_columns = as.character(t_1))
      } else{
        temp <- temp
      }

      direct_transi.df <- lucC_merge(direct_transi.df, temp)
    }
    cat("\n")
  }
)

Forest_Pasture <- direct_transi.df
head(Forest_Pasture)

#Forest_Pasture[ Forest_Pasture == "Pasture" ] <- "Forest_Pasture"
#head(Forest_Pasture)

# plot results
lucC_plot_frequency_events(data_mtx = direct_transi.df,
                     pixel_resolution = 232, custom_palette = FALSE)

# Compute values
measures_Forest_Pasture <- lucC_result_measures(data_mtx = Forest_Pasture, pixel_resolution = 232)
measures_Forest_Pasture



#---------------------------------
# 7- Soybean Moratotium - LUC Calculus
# - Pasture to soybean (deforested before 2006)
#---------------------------------
# 1. All locations (pixels) that are soybean in a year?
# 2. In the past this location (pixel) was pasture in any time?
# 3. This location (pixel) was deforested before 2006? Soy Moratorium.
#
# o = geo-objects, the own df_input data.frame
#---------------------------------

#label2 <- as.character(c("Cerrado", "Crop_Cotton", "Fallow_Cotton", "Forest", "Pasture1", "Pasture2", "Pasture3", "Soybean_Cotton", "Soybean_Crop1", "Soybean_Crop2", "Soybean_Crop3", "Soybean_Crop4", "Soybean_Fallow1", "Soybean_Fallow2", "Water", "Water_mask", "Secondary_vegetation"))

label2 <- as.character(c("Cerrado", "Crop_Cotton", "Fallow_Cotton", "Forest", "Pasture", "Pasture", "Pasture", "Soybean", "Soybean", "Soybean", "Soybean", "Soybean", "Soybean", "Soybean", "Water", "Water", "Secondary_vegetation"))
label2

# create timeline with classified data from SVM method
timeline2 <- lubridate::as_date(c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01", "2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01", "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01", "2016-09-01"))
# soy moratorium
timeline1 <- lubridate::as_date(c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01", "2006-09-01", "2006-09-01", "2006-09-01", "2006-09-01", "2006-09-01", "2006-09-01", "2006-09-01", "2006-09-01", "2006-09-01", "2006-09-01", "2006-09-01"))

# # create timeline with classified data from SVM method
# timeline2 <- lubridate::as_date(c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01", "2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01", "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01", "2016-09-01"))
# # soy moratorium
# timeline1 <- lubridate::as_date(c("2001-09-01", "2002-09-01", "2003-09-01", "2004-09-01", "2005-09-01", "2006-09-01", "2007-09-01", "2008-09-01", "2008-09-01", "2008-09-01", "2008-09-01", "2008-09-01", "2008-09-01", "2008-09-01", "2008-09-01", "2008-09-01"))

# intereting classes
soybean_before.df <- NULL

raster.data <- rb_sits2

# along of all classes
# system.time(
  for(x in 2:length(timeline2)){
    #x = 7
    t_1 <- timeline1[x-1]
    t_2 <- timeline2[x]
    cat(paste0(t_1, ", ", t_2, sep = ""), "\n")

    soybean.df <- lucC_pred_holds(raster_obj = raster.data, raster_class = "Soybean",
                                  time_interval = c(t_2,t_2),
                                  relation_interval = "equals", label = label2, timeline = timeline)

    pasture.df <- lucC_pred_holds(raster_obj = raster.data, raster_class = "Pasture",
                                  time_interval = c(timeline1[1],t_1),
                                  relation_interval = "contains", label = label2, timeline = timeline)

    forest.df <- lucC_pred_holds(raster_obj = raster.data, raster_class = "Forest",
                                 time_interval = c(timeline1[1],t_1),
                                 relation_interval = "contains", label = label2, timeline = timeline)

    fores_past.temp <- lucC_relation_occurs(pasture.df, forest.df)

    temp <- lucC_relation_precedes(soybean.df, fores_past.temp)

    if (!is.null(temp)) {
      tempF <- lucC_select_columns(data_mtx = temp, name_columns = t_2)
    } else {
      tempF <- NULL
    }
    soybean_before.df <- lucC_merge(soybean_before.df, tempF)
  }
#)


#Soybean_Before_2006 <- soybean_before.df
#Soybean_Before_2006[ Soybean_Before_2006 == "Soybean" ] <- "Soybean_Before_2006"
#head(Soybean_Before_2006)

# remove(temp, soybean_before.df, forest.df, pasture.df, soybean.df, fores_past.temp, tempF, t_1, t_2, x)

# plot results
lucC_plot_bar_events(data_mtx = soybean_before.df, pixel_resolution = 231.656, custom_palette = FALSE, side_by_side = TRUE)

## Compute values
# Soybean_Before_2006.tb <- lucC_result_measures(data_mtx = Soybean_Before_2006, pixel_resolution = 231.656)
# Soybean_Before_2006.tb
#
# # plot
# colors_3 <- c("#b3cc33", "#d1f0f7", "#8ddbec", "#228b22", "#7ecfa4", "#b6a896", "#3a3aff", "red", "#b6a896", "#b69872", "#b68549", "#9c6f38", "#e5c6a0", "#e5a352", "#0000ff", "#3a3aff", "red")
#
# lucC_plot_raster(raster_obj = raster.data, timeline = timeline,
#                  label = label2, custom_palette = TRUE,
#                  RGB_color = colors_3, relabel = FALSE, plot_ncol = 6)
#
# lucC_plot_raster_result(raster_obj = raster.data, data_mtx = Soybean_Before_2006, timeline = timeline,
#                  label = label2, custom_palette = TRUE,
#                  RGB_color = colors_3, relabel = FALSE, plot_ncol = 6, shape_point = ".")
#


#---------------------------------
# 8 - Soybean Moratotium - LUC Calculus
# - Pasture to soybean (deforested after 2006)
#---------------------------------
# 1. All locations (pixels) that are soybean in a year?
# 2. In the past this location (pixel) was pasture in any time?
# 3. This location (pixel) was deforested after 2006? Soy Moratorium.
#
# o = geo-objects, the own df_input data.frame
#---------------------------------

#label2 <- as.character(c("Cerrado", "Crop_Cotton", "Fallow_Cotton", "Forest", "Pasture1", "Pasture2", "Pasture3", "Soybean_Cotton", "Soybean_Crop1", "Soybean_Crop2", "Soybean_Crop3", "Soybean_Crop4", "Soybean_Fallow1", "Soybean_Fallow2", "Water", "Water_mask", "Secondary_vegetation"))

label2 <- as.character(c("Cerrado", "Crop_Cotton", "Fallow_Cotton", "Forest", "Pasture", "Pasture", "Pasture", "Soybean", "Soybean", "Soybean", "Soybean", "Soybean", "Soybean", "Soybean", "Water", "Water", "Secondary_vegetation"))
label2

# create timeline with classified data from SVM method
timeline2 <- lubridate::as_date(c("2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01", "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01", "2016-09-01"))

# soy moratorium
timeline1 <- lubridate::as_date(c("2006-09-01", "2007-09-01", "2008-09-01", "2009-09-01", "2010-09-01", "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01", "2016-09-01"))

# # create timeline with classified data from SVM method
# timeline2 <- lubridate::as_date(c("2008-09-01", "2009-09-01", "2010-09-01", "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01", "2016-09-01"))
#
# # soy moratorium
# timeline1 <- lubridate::as_date(c("2008-09-01", "2009-09-01", "2010-09-01", "2011-09-01", "2012-09-01", "2013-09-01", "2014-09-01", "2015-09-01", "2016-09-01"))

# intereting classes
soybean_after.df <- NULL

raster.data <- rb_sits2

# along of all classes
system.time(
  for(x in 2:length(timeline2)){
    #    x = 3
    t_1 <- timeline1[x-1]
    t_2 <- timeline2[x]
    cat(paste0(t_1, ", ", t_2, sep = ""), "\n")

    soybean.df <- lucC_pred_holds(raster_obj = raster.data, raster_class = "Soybean",
                                  time_interval = c(t_2,t_2),
                                  relation_interval = "equals", label = label2, timeline = timeline)

    pasture.df <- lucC_pred_holds(raster_obj = raster.data, raster_class = "Pasture",
                                  time_interval = c(timeline1[1],t_1),
                                  relation_interval = "contains", label = label2, timeline = timeline)

    forest.df <- lucC_pred_holds(raster_obj = raster.data, raster_class = "Forest",
                                 time_interval = c(timeline1[1],t_1),
                                 relation_interval = "contains", label = label2, timeline = timeline)

    fores_past.temp <- lucC_relation_occurs(pasture.df, forest.df)

    temp <- lucC_relation_precedes(soybean.df, fores_past.temp)

    if (!is.null(temp)) {
      tempF <- lucC_select_columns(data_mtx = temp, name_columns = t_2)
    } else {
      tempF <- NULL
    }
    soybean_after.df <- lucC_merge(soybean_after.df, tempF)
  }
)

#Soybean_After_2006 <- soybean_after.df
#Soybean_After_2006[ Soybean_After_2006 == "Soybean" ] <- "Soybean_After_2006"
#head(Soybean_After_2006)

# remove(temp, soybean_before.df, forest.df, pasture.df, soybean.df, fores_past.temp, tempF, t_1, t_2, x)

# plot results
lucC_plot_bar_events(data_mtx = soybean_after.df, pixel_resolution = 231.656, custom_palette = FALSE, side_by_side = TRUE)

# # Compute values
# Soybean_After_2006.tb <- lucC_result_measures(data_mtx = Soybean_After_2006, pixel_resolution = 231.656)
# Soybean_After_2006.tb
#
# # plot
# colors_3 <- c("#b3cc33", "#d1f0f7", "#8ddbec", "#228b22", "#7ecfa4", "#b6a896", "#3a3aff", "red", "#b6a896", "#b69872", "#b68549", "#9c6f38", "#e5c6a0", "#e5a352", "#0000ff", "#3a3aff", "red")
#
# lucC_plot_raster(raster_obj = raster.data, timeline = timeline,
#                  label = label2, custom_palette = TRUE,
#                  RGB_color = colors_3, relabel = FALSE, plot_ncol = 6)
#
# lucC_plot_raster_result(raster_obj = raster.data, data_mtx = Soybean_After_2006, timeline = timeline,
#                         label = label2, custom_palette = TRUE,
#                         RGB_color = colors_3, relabel = FALSE, plot_ncol = 6, shape_point = ".")

#--------------------------------------------------------------


Soy <- lucC_merge(Soybean_Before_2006, Soybean_After_2006)
head(Soy)

lucC_plot_bar_events(data_mtx = Soy, pixel_resolution = 231.656, custom_palette = FALSE, side_by_side = TRUE)


.



.

#------------------------------------
# explit a raster by blocks
#------------------------------------
blocks <- lucC_create_blocks(rb_sits2, number_cells = 400)
blocks

lucC_plot_raster(raster_obj = blocks[[1]], timeline = timeline,
                 label = label2, custom_palette = TRUE,
                 RGB_color = colors_3, relabel = FALSE, plot_ncol = 6)

lucC_plot_raster(raster_obj = blocks[[2]], timeline = timeline,
                 label = label2, custom_palette = TRUE,
                 RGB_color = colors_3, relabel = FALSE, plot_ncol = 6)

