      body: RefreshIndicator(
        onRefresh: _loadProperties,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (companyProv.currentCompany.showCarousel)
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                    child: _buildCarousel(companyProv.currentCompany),
                  ),
                ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                child: Row(
                  children: [
                    DropdownButton<PropertySortOption>(
                      value: _sortOption,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.sort, size: 16),
                      onChanged: (v) => setState(() => _sortOption = v!),
                      items: [
                        DropdownMenuItem(value: PropertySortOption.newest, child: Text(isSpanish ? 'Nuevos' : 'Newest')),
                        DropdownMenuItem(value: PropertySortOption.priceAsc, child: Text(isSpanish ? 'Precio Min' : 'Price Asc')),
                        DropdownMenuItem(value: PropertySortOption.priceDesc, child: Text(isSpanish ? 'Precio Max' : 'Price Desc')),
                        DropdownMenuItem(value: PropertySortOption.mostLiked, child: Text(isSpanish ? 'Más populares' : 'Most Popular')),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppThemes.primaryGreen, foregroundColor: Colors.white),
                      onPressed: () => _showFilterDialog(context),
                      icon: const Icon(Icons.tune, size: 18),
                      label: Text(l10n.get('filter')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProperties.isEmpty
                      ? Center(child: Padding(padding: const EdgeInsets.all(40), child: Text(isSpanish ? 'Sin resultados' : 'No results')))
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: isMobile
                              ? Column(
                                  children: _filteredProperties
                                      .map((p) => Padding(
                                            padding: const EdgeInsets.only(bottom: 24),
                                            child: PropertyCard(
                                              property: p,
                                              initialLikeCount: _likeCounts[p.id] ?? 0,
                                              initialIsLiked: _likedByMe.contains(p.id),
                                              visitorId: _visitorId ?? '',
                                              onLikeToggled: (count, liked) {
                                                _likeCounts[p.id!] = count;
                                                if (liked) _likedByMe.add(p.id!); else _likedByMe.remove(p.id!);
                                              },
                                            ),
                                          ))
                                      .toList())
                              : GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 500, childAspectRatio: 0.75, crossAxisSpacing: 24, mainAxisSpacing: 24),
                                  itemCount: _filteredProperties.length,
                                  itemBuilder: (_, i) {
                                    final p = _filteredProperties[i];
                                    return PropertyCard(
                                      property: p,
                                      initialLikeCount: _likeCounts[p.id] ?? 0,
                                      initialIsLiked: _likedByMe.contains(p.id),
                                      visitorId: _visitorId ?? '',
                                      onLikeToggled: (count, liked) {
                                        _likeCounts[p.id!] = count;
                                        if (liked) _likedByMe.add(p.id!); else _likedByMe.remove(p.id!);
                                      },
                                    );
                                  },
                                ),
                        ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
