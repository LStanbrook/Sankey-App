# Sankey network creation
sankey_gen <- function(html = FALSE){
  
  if (input$update == 0){
    return()
  }
  
  data_sub <- data_sub()
  
  ## Pathname config
  pathname <- input$pathname
  
  get_dates <- function(data_sub) {
    dates <- data_sub %>% 
      pull(PATHNAME_ENCODED) %>%
      unique() %>%
      droplevels() %>%
      levels()
    
    if (str_detect(dates[1], '-')) {
      dates <- dates %>%
        paste(collapse = '.') %>% 
        str_replace_all('\\.[A-Za-z0-9]*', '') %>%
        str_split(' - ')
    } else {
      dates <- ''
      showNotification('Not correct Pathname format, check help page example.', type = 'warning')
    }
    
    return(dates)
  }
  
  if (isolate(input$timepoint_labels) && pathname != '') {
    dates <- get_dates(data_sub)
  } else {
    dates <- ''
    if (pathname == '') {
      showNotification('No Pathname column provided.', type = 'warning')
    }
  }
  
  # nodedata
  paths <- data_sub$PATHNO_ENCODED %>% 
    unique() %>% 
    sort()
  
  total_vec <- c()
  total_no_list <- c()
  # paths_vec <- c()
  
  ## Get all starting nodes from each path
  for (p in paths){
    nodes_p <- paste(unique(data_sub%>%
                              filter(PATHNO_ENCODED==p)%>%
                              pull(NODE_S_ENCODED)
    )
    )
    
    nodes_p <- nodes_p[order(nodes_p)]
    
    total_vec <- total_vec %>%
      append(nodes_p)
    
    total_no_list <- total_no_list %>%
      append(length(total_vec))
    
    # paths_vec <- paths_vec %>%
    #   append(rep(p, length(nodes_p)))
  }
  
  ## Get the final layer of nodes by the end nodes of the final path
  nodes_p <- paste(unique(data_sub%>%
                            filter(PATHNO_ENCODED==p)%>%
                            pull(NODE_E_ENCODED)
  )
  )
  
  nodes_p <- nodes_p[order(nodes_p)]
  
  total_vec <- total_vec %>%
    append(nodes_p)
  
  total_no_list <- total_no_list %>%
    append(length(total_vec))
  
  # paths_vec <- paths_vec %>%
  #   append(rep(p+1, length(nodes_p)))
  
  nodedata<-data.frame(node = c(0:(length(total_vec)-1)), name = total_vec,stringsAsFactors = FALSE) 
  
  timepoints <- c()
  
  for (i in 1:length(paths)){
    if (i == 1){
      timepoints <- c(timepoints,rep(paths[i],total_no_list[i]))
    } else {
      timepoints <- c(timepoints,rep(paths[i],total_no_list[i]-total_no_list[i-1]))
    }
    
  }
  
  timepoints <- c(timepoints,rep(paths[i]+1,total_no_list[i+1]-total_no_list[i]))
  
  nodedata$timepoint <- timepoints
  
  # origin node
  origins <- data_sub %>%
    filter(PATHNO_ENCODED == paths[1]) %>%
    select(USUBJID_ENCODED, NODE_S_ENCODED) %>% 
    rename(ORIGIN = NODE_S_ENCODED)
  
  if (isolate(input$mode_switch)){
    if (isolate(input$orig_path) %in% paths){
      origins <- data_sub %>%
        filter(PATHNO_ENCODED == isolate(input$orig_path)) %>%
        select(USUBJID_ENCODED, NODE_S_ENCODED) %>% 
        rename(ORIGIN = NODE_S_ENCODED)
    } else {
      origins <- data_sub %>%
        filter(PATHNO_ENCODED == (isolate(input$orig_path)-1)) %>%
        select(USUBJID_ENCODED, NODE_E_ENCODED) %>% 
        rename(ORIGIN = NODE_E_ENCODED)
    }
  }

  ## New code for processing the inputted data
  # Counts for each unique path2
  sankey_data <- data_sub %>%
    group_by(NODE_S_ENCODED, NODE_E_ENCODED, PATHNO_ENCODED) %>%
    summarise(value = n(), .groups = 'drop') %>%
    mutate(probability = value / sum(value), value = value) %>%
    rename(source = NODE_S_ENCODED, target = NODE_E_ENCODED, PATHNO = PATHNO_ENCODED)
  
  # Calculate the total value within each PATHNO
  total_counts <- sankey_data %>%
    group_by(PATHNO) %>%
    summarise(total_count = sum(value), .groups = 'drop')
  
  # Join the total_counts back to the original data to normalize the probability
  sankey_data <- sankey_data %>%
    left_join(total_counts, by = "PATHNO") %>%
    mutate(probability = value / total_count, value = value) %>%
    select(-total_count)
  
  # Removing duplicates
  sankey_data <- sankey_data %>% filter(probability != 0)
  
  sankey_data$probability_org <- sankey_data$probability
  sankey_data$probability <- as.numeric(sankey_data$probability)
  sankey_data$probability_org <- as.numeric(sankey_data$probability_org)
  sankey_data$value <- as.numeric(sankey_data$value)
  sankey_data$PATHNO <- as.integer(sankey_data$PATHNO)
  
  sankey_data <- as.data.frame(sankey_data)
  sankey_data$PATHNO <- as.integer(sankey_data$PATHNO)
  
  sankey_data <- sankey_data[order(sankey_data$PATHNO, sankey_data$source, sankey_data$target), ]
  
  sankey_data %>%
    group_by(PATHNO) %>%
    summarise(total_probability = sum(probability, na.rm = TRUE), total_counts = sum(value, na.rm = TRUE))
  
  sankey_data <- sankey_data[order(sankey_data$PATHNO),]
  sankey_data_subset <- sankey_data
  
  data_sub <- data_sub %>%
    merge(., origins, by = 'USUBJID_ENCODED')
  
  # links
  no_of_paths2 = length(paths)
  
  for (i in 1:no_of_paths2){
    ## Gathering links and number for each path
    data_p <- data_sub %>% 
      filter(PATHNO_ENCODED == paths[i]) %>%
      group_by(NODE_S_ENCODED, NODE_E_ENCODED, ORIGIN) %>%
      summarise(value = n(), PATHNO_ENCODED = mean(PATHNO_ENCODED)) 
    
    nodes_s <- nodedata %>%
      filter(timepoint == paths[i])
    
    nodes_e <- nodedata %>%
      filter(timepoint == (paths[i]+1))
    ## Encoding nodes
    data_p <- data_p %>%
      merge(nodes_s, by.x = "NODE_S_ENCODED", by.y = "name", all = TRUE) %>%
      merge(nodes_e, by.x = "NODE_E_ENCODED", by.y = "name", all =TRUE)
    
    if (i==1){
      links <- data_p
    } else {
      links <- rbind(links, data_p)
    }
  }
  
  links <- links[order(links$PATHNO_ENCODED, links$value),] 
  
  # Ordering
  no_nodes = length(nodedata$node)
  
  ## will contain all the nodes for each path ordered by path and then by size
  nodedata_ord <- nodedata[0,]
  
  for (i in 1:no_of_paths2){
    ## getting the size of each node
    path <- links %>% 
      filter(PATHNO_ENCODED == paths[i]) %>%
      group_by(NODE_S_ENCODED) %>%
      summarise(size = sum(value))  %>%
      rename(name = NODE_S_ENCODED)
    
    
    nodedata_1 <- NULL
    
    nodedata_1 <- nodedata %>%
      filter(timepoint == paths[i]) %>%
      merge(path, by = 'name') 
    
    ## order them by size
    nodedata_1 <- nodedata_1[order(nodedata_1$size, nodedata_1$name),c(2,1,4,3)] 
    ## group nodes by size
    if (isolate(input$top_nodes)){
      if (isolate(input$advanced_top)){
        top_nodes <- isolate(input[[paste0('top_nodes_no', paths[i])]])
      } else {
        top_nodes <- isolate(input$top_nodes_no)
      }
      
      if (top_nodes < nrow(nodedata_1)){
        nodedata_1_top <- nodedata_1[(nrow(nodedata_1)-top_nodes + 1):nrow(nodedata_1),] 
        nodedata_1_bottom <- nodedata_1[1:(nrow(nodedata_1)-top_nodes),] 
        id <- nodedata_1_bottom[1, 1]
        size_other <- nodedata_1_bottom$size %>% sum()
        nodedata_1 <- rbind(c(id, 'Other', size_other, paths[i]), nodedata_1_top)
      }
    }
    
    
    nodedata_ord <- rbind(nodedata_ord, nodedata_1)
  }
  ## final layer - same process
  path <- links %>% 
    filter(PATHNO_ENCODED == paths[no_of_paths2]) %>%
    group_by(NODE_E_ENCODED) %>%
    summarise(size = sum(value))  %>%
    rename(name = NODE_E_ENCODED)
  
  nodedata_1 <- NULL
  
  nodedata_1 <- nodedata %>%
    filter(timepoint == paths[i]+1) %>%
    merge(path, by = 'name') 
  
  nodedata_1 <- nodedata_1[order(nodedata_1$size, nodedata_1$name),c(2,1,4,3)] 
  
  if (isolate(input$top_nodes)){
    if (isolate(input$advanced_top)){
      top_nodes <- isolate(input[[paste0('top_nodes_no', paths[i]+1)]])
    }
    if (top_nodes < nrow(nodedata_1)){
      nodedata_1_top <- nodedata_1[(nrow(nodedata_1)-top_nodes + 1):nrow(nodedata_1),] 
      nodedata_1_bottom <- nodedata_1[1:(nrow(nodedata_1)-top_nodes),] 
      id <- nodedata_1_bottom[1, 1]
      size_other <- nodedata_1_bottom$size %>% sum()
      nodedata_1 <- rbind(c(id, 'Other', size_other, paths[i]+1), nodedata_1_top)
    }
  }
  
  nodedata_ord <- rbind(nodedata_ord, nodedata_1)
  
  row.names(nodedata_ord) <- NULL
  no_nodes <- nrow(nodedata_ord)
  
  ## Order Nodedata by name
  if (isolate(input$order)){
    if (isolate(input$order_option == 'Name')){
      nodedata_ord <- nodedata_ord[order(nodedata_ord$timepoint, nodedata_ord$name),] 
    }
  }
  nodedata_ord$node_ord <- (1:no_nodes-1)
  
  ## Redo the link creation but with known order
  if (isolate(input$top_nodes)){
    grouped_nodes_or <- nodedata_ord %>%
      filter(timepoint == min(timepoint)) %>%
      pull(name)  
    
    if (isolate(input$mode_switch)){
      selected_timepoint <- isolate(input$orig_path)
      grouped_nodes_or <- nodedata_ord %>% 
        filter(timepoint == selected_timepoint) %>%
        pull(name) 
    }
  }
  
  
  for (i in 1:no_of_paths2){
    data_p <- data_sub %>% 
      filter(PATHNO_ENCODED == paths[i]) %>%
      group_by(NODE_S_ENCODED, NODE_E_ENCODED, ORIGIN) %>%
      summarise(value = n(), PATHNO_ENCODED = mean(PATHNO_ENCODED)) 
    
    if (isolate(input$top_nodes)){
      nodes_s <- nodedata_ord %>% 
        filter(timepoint == paths[i])
      
      nodes_e <- nodedata_ord %>% 
        filter(timepoint == (paths[i]+1))
      
      grouped_nodes_s <- nodes_s %>%
        pull(name)
      grouped_nodes_e <- nodes_e %>%
        pull(name)
      
      
      data_p[!(data_p$NODE_S_ENCODED %in% grouped_nodes_s), 'NODE_S_ENCODED'] <- 'Other'
      data_p[!(data_p$NODE_E_ENCODED %in% grouped_nodes_e), 'NODE_E_ENCODED'] <- 'Other'
      
      data_p[!(data_p$ORIGIN %in% grouped_nodes_or), 'ORIGIN'] <- 'Other' 
      
      data_p <- data_p %>%
        group_by(NODE_S_ENCODED, NODE_E_ENCODED, ORIGIN) %>%
        summarise(value = sum(value), PATHNO_ENCODED = mean(PATHNO_ENCODED))%>%
        merge(nodes_s, by.x = "NODE_S_ENCODED", by.y = "name", all = TRUE) %>%
        merge(nodes_e, by.x = "NODE_E_ENCODED", by.y = "name", all =TRUE)
      
      
      if (i==1){
        links <- data_p
      }
      else {
        links <- rbind(links, data_p)
      }
    } else {
      nodes_s <- nodedata_ord %>% 
        filter(timepoint == paths[i])
      
      nodes_e <- nodedata_ord %>% 
        filter(timepoint == (paths[i]+1))
      
      data_p <- data_p %>%
        merge(nodes_s, by.x = "NODE_S_ENCODED", by.y = "name", all = TRUE) %>%
        merge(nodes_e, by.x = "NODE_E_ENCODED", by.y = "name", all =TRUE)
      
      if (i==1){
        links <- data_p
      }
      else {
        links <- rbind(links, data_p)
      }
    }
    
  }
  
  links <- links[order(links$PATHNO_ENCODED, links$value),] 
  if (isolate(input$order)){
    if (isolate(input$order_option == 'Name')){
      links <- links[order(links$PATHNO_ENCODED, links$NODE_S_ENCODED, links$NODE_E_ENCODED),]
    }
  }
  
  ## if iteration 0 sankey keeps the order given to it
  ## otherwise it finds the one that makes the links the most visible
  if (isolate(input$order)){
    iterations = 0
  }
  else {
    iterations = 32
  }
  
  # grouping color 
  treatment <- c()
  ## grouping colours
  rand_colors <- brewer.pal(12, "Paired") %>%
    append(brewer.pal(8, "Dark2")) %>%
    append(brewer.pal(11, "Spectral")) %>%
    #append(brewer.pal(11, "PRGn")) %>%
    append(brewer.pal(6, "Set1")) %>%
    append(brewer.pal(11, "BrBG")) %>%
    append(brewer.pal(11, "RdGy"))   

  if (!isolate(input$node_unique)) {
    # Create a dictionary to store assignments for names not hitting any condition
    name_assignments <- list()
    
    for (x in nodedata_ord$name) {
      if (regexpr(isolate(input$color), x, ignore.case = TRUE)[[1]][1] != -1) {
        treatment <- treatment %>% append("1")
      } else if (grepl("IDFS$", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("1")
      } else if (grepl("NMR$", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("2")
      } else if (grepl("MR$", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("3")
      } else if (grepl("(Death$|_D$)", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("4")
      } else if (grepl("(Disc. ?Study)|(Discontinued ?Study)", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("3")
      } else if (grepl("(No ?Trt.?)|(No ?Treatment)|(None)|(Other)|([Mm]issing)", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("4")
      } else {
        # Check if the name already has an assignment
        if (!x %in% names(name_assignments)) {
          # Assign a random number from 1 to 4
          name_assignments[[x]] <- as.character(sample(1:4, 1))
        }
        treatment <- treatment %>% append(name_assignments[[x]])
      }
    }    
    
    nodedata_ord$group <- treatment
    
    node_groups <- paste0("'",1:4,"'") %>% 
      paste(collapse=',')
    
    node_colours <- paste0("'",c(isolate(input$color_1),isolate(input$color_2),isolate(input$color_3),isolate(input$color_4)),"'") %>% 
      paste(collapse=',')
    
  } else {
    nodedata_ord$group <- nodedata_ord$name %>%
      str_replace_all(' ', '_')
    
    node_groups2 <- nodedata_ord$group %>%
      unique() %>%
      str_replace_all(' ', '_')
    node_groups <- paste0("'",node_groups2,"'") %>% 
      paste(collapse=',')
    
    node_colours <- paste0("'", rand_colors[1:length(node_groups2)],"'") %>% 
      paste(collapse=',')
  }
  
  
  if (isolate(input$mode_switch)){
    link_group <- "ORIGIN2"     
    links$ORIGIN2 <- links$ORIGIN %>%
      str_replace_all(' ', '_')
    
    my_groups <- links$ORIGIN2 %>%
      unique() 
    
    link_colours <- rand_colors[1:length(my_groups)] %>% 
      paste(., collapse = "','")
    
    link_groups <- my_groups %>%
      paste(., collapse = "','")
    
    link_colours <- paste0("'", link_colours, "'")
    link_groups <- paste0("'", link_groups, "'")
    
  }else if (isolate(input$mode_switch2)){
    link_group <- paste0(isolate(input$node_s_e),'_ENCODED2')
    links[,link_group] <- links[,paste0(isolate(input$node_s_e),'_ENCODED')] %>%
      str_replace_all(' ', '_')
    
    my_groups <- links[,link_group] %>%
      unique() 
    
    link_colours <- rand_colors[1:length(my_groups)] %>% 
      paste(., collapse = "','")
    
    link_groups <- my_groups %>%
      paste(., collapse = "','")
    
    link_colours <- paste0("'", link_colours, "'")
    link_groups <- paste0("'", link_groups, "'")
    
  }else{
    
    if (isolate(input$link_group)!="None" & isolate(input$link_group)!="none" ){
      link_col <- c()
      t_node_s <- grepl(isolate(input$link_group), links$NODE_S_ENCODED, ignore.case = TRUE)
      t_node_e <- grepl(isolate(input$link_group), links$NODE_E_ENCODED, ignore.case = TRUE)
      for (x in 1:length(links$NODE_S_ENCODED)){
        if (t_node_s[x] | t_node_e[x]){
          link_col <- link_col%>%append("a")
        }
        else{
          link_col <- link_col%>%append("b")
        }
      }
      links$color <-link_col
      
      link_groups <- paste0("'",c('a', 'b'),"'") %>% 
        paste(collapse=',')
      
      link_colours <- paste0("'", c('#ff4500','rgb(0,0,0)'),"'") %>% 
        paste(collapse=',')
      
      if (html){
        link_colours <- paste0("'", c('#ff4500','rgb(0,0,0,.2)'),"'") %>% 
          paste(collapse=',')
      }
      link_group <- "color"                  
    } else {
      link_group <- NULL
      
      link_groups <- paste0("'",c('a', 'b'),"'") %>% 
        paste(collapse=',')
      
      link_colours <- paste0("'", c('#ff4500','rgb(0,0,0)'),"'") %>% 
        paste(collapse=',')
    }
  }
  
  links <- links %>%
    group_by(PATHNO_ENCODED) %>%
    mutate(probability = value / sum(value))
  
  # To ensure the dataframe is not grouped after this operation
  links <- ungroup(links)
  
  links <- as.data.frame(links)
  
  # Creates a variable for the unique path2 numbers from the data, then sorts it in ascending order 
  unique_path_no <- sankey_data_subset$PATHNO %>%
    unique() %>% 
    sort()
  
  # Instantiates two list variables for use in the following for loop
  total_nodes <- c()
  total_num_list <- c()
  
  # For each unique path2 number, the unique starting nodes are pulled from our dataset.
  for (p in unique_path_no){
    node_temp <- paste(unique(sankey_data_subset %>%
                                filter(PATHNO == p) %>%
                                pull(source)))
    
    # Orders the starting nodes
    node_temp <- node_temp[order(node_temp)]
    
    # Appends the starting nodes of each path2
    total_nodes <- total_nodes %>%
      append(node_temp)
    
    # Appends the cumulative total number of unique starting nodes after each path2
    total_num_list <- total_num_list %>%
      append(length(total_nodes))
  }
  
  # Overwrites the node_temp variable to include names of unique end nodes on any path2
  node_temp <- paste(unique(sankey_data_subset %>%
                              filter(PATHNO == p) %>%
                              pull(target)))
  
  # Orders these nodes in alphabetical order
  node_temp <- node_temp[order(node_temp)]
  
  # Adds the end nodes to end of our vec list
  total_nodes <- total_nodes %>%
    append(node_temp)
  
  # Adds the cumulative length of the vec list to our number list
  total_num_list <- total_num_list %>%
    append(length(total_nodes))
  
  # Creates a variable that creates unique ID for each node in our vec list.
  node_data <- data.frame(node = c(0:(length(total_nodes) - 1)), name = total_nodes, stringsAsFactors = FALSE) 
  
  # Creates a variable for the length of our path2 variable i.e. number of unique unique_path_no
  no_of_paths2 <- length(unique_path_no)
  
  # For each path2, the data is grouped by the path2 combo (start and end nodes) and the probability associated with that combination 
  for (i in 1:no_of_paths2){
    # Gathering path_links and number for each path2
    sankey_data_p <- sankey_data_subset %>% 
      filter(PATHNO == unique_path_no[i]) %>%
      group_by(source, target, probability, value) %>%
      summarise(PATHNO = mean(PATHNO))
    
    # If it is the first path2, it merges the first probability of node_data (number of nodes for first path2) sankey_data_p variable
    # and creates by variables for names of starting and ending nodes then assigns this to a path_links variable.
    if (i == 1){
      sankey_data_p <- sankey_data_p %>%
        merge(node_data[1:total_num_list[1],], by.x = "source", by.y = "name", all = TRUE) %>%
        merge(node_data[(total_num_list[1] + 1):total_num_list[2],], by.x = "target", by.y = "name", all = TRUE)
      path_links <- sankey_data_p
    }
    # If it is not the first path2, it instead creates the variables for names of starting and ending nodes for that path2 and adds
    # it to the path_links variable.
    else {
      sankey_data_p <- sankey_data_p %>%
        merge(node_data[(total_num_list[i - 1] + 1):total_num_list[i],], by.x = "source", by.y = "name", all = TRUE) %>%
        merge(node_data[(total_num_list[i] + 1):total_num_list[i + 1],], by.x = "target", by.y = "name", all = TRUE)
      
      path_links <- rbind(path_links, sankey_data_p)
    }
  }
  
  # Orders the path_links variable we just created by the path2 number and probability
  path_links <- path_links[order(path_links$PATHNO, path_links$probability),] 
  
  # Creating a variable to add a 0 to the start of the number list
  total_no_list_2 <- c(0, total_num_list)
  # Creating a variable for the length of node variable (number of nodes)
  num_nodes <- length(node_data$node)
  
  # Will contain all the nodes for each path2 ordered by path2 and then by size
  # New data frame variable that is an empty version of node_data
  node_data_ord <- node_data[0,]
  
  # For each path2, it adds the starting node and size to the path2 variable
  for (i in 1:no_of_paths2){
    # Getting the size of each node
    path2 <- path_links %>% 
      filter(PATHNO == unique_path_no[i]) %>%
      group_by(source) %>%
      summarise(size = sum(probability)) %>%
      rename(name = source)
    
    # For each path2 it also makes a variable for the node number for each node
    node_data_1 <- NULL
    node_data_1 <- node_data[(total_no_list_2[i] + 1):total_no_list_2[i + 1],] %>%
      merge(path2, by = 'name') 
    
    # It is then ordered by ID and all added to one variable
    node_data_1 <- node_data_1[order(node_data_1$size), c(2, 1)] 
    node_data_ord <- rbind(node_data_ord, node_data_1)
  }
  
  # The path2 variable is overwritten by one where it filters for the final path2 number, and gives it the probability of 
  # the end nodes and the size of each one.
  path2 <- path_links %>% 
    filter(PATHNO == unique_path_no[no_of_paths2]) %>%
    group_by(target) %>%
    summarise(size = sum(probability)) %>%
    rename(name = target)
  
  # For each path2 it also makes a variable for the node number for each node
  node_data_1 <- NULL
  node_data_1 <- node_data[(total_no_list_2[length(total_no_list_2) - 1] + 1):total_no_list_2[length(total_no_list_2)],] %>%
    merge(path2, by = 'name') 
  
  # It is then ordered by ID and all added to one variable
  node_data_1 <- node_data_1[order(node_data_1$size), c(2, 1)] 
  node_data_ord <- rbind(node_data_ord, node_data_1)
  
  # Removes row names
  row.names(node_data_ord) <- NULL
  # Adds new column for ID
  node_data_ord$node_ord <- (1:num_nodes - 1)
  
  node_probabilities <- sankey_data %>%
    select(source, target, probability, value, PATHNO) %>%
    arrange(PATHNO, source, target) %>%
    group_by(PATHNO, source, target) %>%
    summarize(total_probability = sum(probability), total_count = sum(value)) %>%
    distinct()
  
  # Create a new pipe to add one new observation for each unique source node in PATHNO 1
  node_probabilities <- node_probabilities %>%
    bind_rows(
      node_probabilities %>%
        filter(PATHNO == 1) %>%
        group_by(source) %>%
        summarize(
          total_probability = sum(total_probability),
          total_count = sum(total_count),
          PATHNO = 0,
          target = first(source)
        ) %>%
        ungroup()
    )
  
  # Combine all observations with the same PATHNO and target nodes
  node_probabilities <- node_probabilities %>%
    group_by(PATHNO, target) %>%
    summarize(
      total_probability = sum(total_probability),
      total_count = sum(total_count),
      source = first(source)
    ) %>%
    ungroup()
  
  node_data_ord <- node_data_ord[order(node_data_ord$name, node_data_ord$node_ord), ]
  node_probabilities <- node_probabilities[order(node_probabilities$target, node_probabilities$PATHNO), ]
  
  node_data_ord2 <- node_data_ord %>%
    mutate(target = node_probabilities$target,
           probability = node_probabilities$total_probability,
           value = node_probabilities$total_count,
           PATHNO = node_probabilities$PATHNO
    )
  
  # Print the resulting data frame
  node_data_ord2 <- node_data_ord2[order(node_data_ord2$node_ord), ]
  
  node_data_ord2 <- node_data_ord2 %>%
    mutate(name_prob = paste0(name, " : ", value, " (", round(probability * 100, 2), "%)"))
  
  node_data_ord2$timepoint <- as.numeric(node_data_ord2$PATHNO + 1)
  
  treatment <- c()
  node_groups <- c()
  node_colours <- c()
  node_groups2 <- c()
  
  if (!isolate(input$node_unique)) {
    # Create a dictionary to store assignments for names not hitting any condition
    name_assignments <- list()
    
    for (x in nodedata_ord$name) {
      if (regexpr(isolate(input$color), x, ignore.case = TRUE)[[1]][1] != -1) {
        treatment <- treatment %>% append("1")
      } else if (grepl("IDFS$", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("1")
      } else if (grepl("NMR$", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("2")
      } else if (grepl("MR$", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("3")
      } else if (grepl("(Death$|_D$)", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("4")
      } else if (grepl("(Disc. ?Study)|(Discontinued ?Study)", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("3")
      } else if (grepl("(No ?Trt.?)|(No ?Treatment)|(None)|(Other)|([Mm]issing)", x, ignore.case = TRUE)) {
        treatment <- treatment %>% append("4")
      } else {
        # Check if the name already has an assignment
        if (!x %in% names(name_assignments)) {
          # Assign a random number from 1 to 4
          name_assignments[[x]] <- as.character(sample(1:3, 1))
        }
        treatment <- treatment %>% append(name_assignments[[x]])
      }
    }
    
    node_data_ord2$group <- treatment
    
    node_groups <- paste0("'",1:4,"'") %>% 
      paste(collapse=',')
    
    node_colours <- paste0("'",c(isolate(input$color_1),isolate(input$color_2),isolate(input$color_3),isolate(input$color_4)),"'") %>% 
      paste(collapse=',')
    
  } else {
    node_data_ord2$group <- node_data_ord2$name %>%
      str_replace_all(' ', '_')
    
    node_groups2 <- node_data_ord2$group %>%
      unique() %>%
      str_replace_all(' ', '_')
    node_groups <- paste0("'",node_groups2,"'") %>% 
      paste(collapse=',')
    
    node_colours <- paste0("'", rand_colors[1:length(node_groups2)],"'") %>% 
      paste(collapse=',')
  }
  
  my_color <- paste0('d3.scaleOrdinal().domain([',node_groups,', ',link_groups,']).range([',node_colours,', ',link_colours,'])')
  
  
  margin = list(top = isolate(input$margin_top),
                bottom = isolate(input$margin_bottom),
                left = isolate(input$margin_left),
                right = isolate(input$margin_right))
  
  
  #Sankey
  sankey <- sankeyNetwork(Links = links,
                          Nodes = node_data_ord2,
                          Source = "node_ord.x",
                          Target = "node_ord.y",
                          Value = "value", 
                          NodeID = "name_prob",
                          LinkGroup = link_group, 
                          NodeGroup = "group",
                          colourScale = my_color,
                          #margin = margin,
                          fontSize = isolate(input$node_font_size),
                          nodeWidth = isolate(input$node_width),
                          nodePadding = isolate(input$node_padding),
                          fontFamily = isolate(input$node_font),
                          sinksRight = FALSE,
                          height = 600,
                          width = 800,
                          iterations = iterations) 
  
  sankey$x$links$ORIGIN <- links$ORIGIN
  sankey$x$links$PATHNO_ENCODED <- links$PATHNO_ENCODED
  sankey$x$nodes$TIMEPOINT <- nodedata_ord$timepoint
  
  ## tooltip rendering with JS 
  ### along with SVG download and origin tracking
  sankey_js <- "www/JS/sankey.js"
  js_code <- readChar(sankey_js, file.info(sankey_js)$size)
  
  # Colour prompt 
  if (isolate(input$manual_colors)){
    js_code <- js_code %>%
      str_replace('powerBI = true', 'powerBI = false') %>%
      str_replace('manual_colors', 'manual_colors = true')
  }
  
  # Title - footnote
  if (isolate(input$general_title)){
    if (isolate(input$general_title_text) != ''){
      js_code <- js_code %>%
        str_replace('title = 1', paste0("title = '", isolate(input$general_title_text), "'")) %>%
        str_replace('title_font', paste0("title_font = '", isolate(input$general_title_font), "'")) %>%
        str_replace('title_size', paste0("title_size = ", isolate(input$general_title_font_size))) %>%
        str_replace('title_x', paste0("title_x = ", isolate(input$general_title_x)))
    }
  }
  
  if (isolate(input$general_footnote)){
    if (isolate(input$general_footnote_text) != ''){
      js_code <- js_code %>%
        str_replace('footnote = 1', paste0("footnote = '", isolate(input$general_footnote_text), "'")) %>%
        str_replace('footnote_font', paste0("footnote_font = '", isolate(input$general_footnote_font), "'")) %>%
        str_replace('footnote_size', paste0("footnote_size = ", isolate(input$general_footnote_font_size))) 
    }
  }
  
  
  # Margins 
  js_code <- js_code %>%
    str_replace('margin_top', paste0('margin_top = ', isolate(input$margin_top))) %>%
    str_replace('margin_left', paste0('margin_left = ', isolate(input$margin_left))) %>%
    str_replace('margin_right', paste0('margin_right = ', isolate(input$margin_right))) %>%
    str_replace('margin_bottom', paste0('margin_bottom = ', isolate(input$margin_bottom))) 
  
  # Switch js_code if link mode switch is on
  if (isolate(input$link_static_opacity)){
    js_code <- js_code %>%
      str_replace('powerBI = true', 'powerBI = false') %>% 
      str_replace('//g', paste0("link.style('stroke-opacity', ", isolate(input$link_static_opacity_num), ")"))
  } else if (isolate(input$mode_switch)){
    
  } else if (isolate(input$mode_switch2)){
    js_code <- js_code %>%
      str_replace('0.901', '0.5')
  } else {
    js_code <- js_code %>%
      str_replace('0.901', '0.2') %>%
      str_replace('//c', "d3.select(this) .style('stroke-opacity', 0.5);") %>%
      str_replace('//d', "d3.select(this) .style('stroke-opacity', 0.2);") %>%
      str_replace('//e', "if(d.x == 0){link.style('stroke-opacity', l => {return l.ORIGIN == d.name ? 0.5 : 0.2;})}") %>%
      str_replace('//f', "link.style('stroke-opacity', 0.2)") 
    
    if (!isolate(input$manual_colors)){
      js_code <- js_code %>%
        str_replace('//b', "d3.select(this).select('rect').style('fill', 'red');") %>%
        str_replace('//b2', "d3.select(this).select('rect').style('fill', fill);")
    }
  }
  
  # Node Opacity
  if (isolate(input$node_static_opacity)){
    js_code <- js_code %>%
      str_replace('powerBI = true', 'powerBI = false') %>% 
      str_replace('//h', paste0("node.select('rect').style('opacity', ", isolate(input$node_static_opacity_num), ")"))
  }
  
  
  ## disabled Show node sizes functionality, could be reworked for different purpose.
  
  # if (isolate(input$node_show)){
  #   js_code <- js_code %>% 
  #     str_replace('units = 1', paste0("units = '", isolate(input$node_units), "'")) %>%
  #     str_replace('//a', "d3.selectAll('.node').select('text').style('font-weight', 'bold').text(d => d.name + ': ' + d.value + units);")
  # }
  
  ## Hide node labels
  if (isolate(input$remove_labels)){
    js_code <- js_code %>% 
      str_replace('nodeHide = false', "nodeHide = true")
  }
  
  ## Remove Missing
  if (isolate(input$remove_missing)){
    js_code <- js_code %>% 
      str_replace('missing = false', "missing = true")
  }
  
  js_code = js_code %>% 
    str_replace("chosenPercentage = \\d+;", paste0("chosenPercentage = ", isolate(input$perc), ";"))
  
  ## Timepoints on graph
  if (isolate(input$timepoint_labels)){
    if (dates != ''){
      dates <- dates %>%
        paste0("'",.,"'") %>% 
        paste(., collapse=',') %>%
        paste0("[",.,"]") %>%
        str_replace("'c\\(", '') %>%
        str_replace("\\)'", '')
      
      js_code <- js_code %>% 
        str_replace('0.0001', dates) %>%
        str_replace('1vw', paste0(isolate(input$timepoints_font_size), 'vw')) %>%
        str_replace('xcoord', paste0('xcoord = ', isolate(input$timepoints_x)))
      
      if (isolate(input$timepoints_font) != ''){
        js_code <- js_code %>%
          str_replace('//i', paste0(".attr('font-family', '", isolate(input$timepoints_font), "')"))
      }
      
    }
    
  }
  
  ## Legend
  if (isolate(input$node_unique)){
    if (isolate(input$legend)){
      js_code <- js_code %>%
        str_replace('legend_bool = false', 'legend_bool = true') %>%
        str_replace('legend_size', paste0('legend_size = ', isolate(input$legend_font_size))) %>%
        str_replace('legend_font', paste0("legend_font = '", isolate(input$legend_font), "'")) %>%
        str_replace('legend_nrow', paste0('legend_nrow = ', isolate(input$legend_nrow))) %>%
        str_replace('legend_x', paste0('legend_x = ', isolate(input$legend_x))) %>%
        str_replace('legend_title', paste0("legend_title = '", isolate(input$legend_title), "'"))
    }
  } 
  
  
  sankey <- onRender(sankey,js_code)
  
  return(sankey)
}


# Sankey Rendering
output$SankeyPlot <- renderSankeyNetwork({
  sankey_gen()
})
